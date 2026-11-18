# Feature tests of the installed GHC 6.2.2.  Usage: run.sh SRC GHC REF OUT
#
# SRC holds the test programs, GHC and REF are the bin directories of GHC 6.2.2
# and of the reference compiler (for the Haskell 98 programs), and OUT receives
# report.txt and a log per check.  Every check runs in its own subshell with
# set -e, so one failure does not stop the others.  XFAIL marks a feature that
# this build of 6.2.2 does not have, with the message it gives.

src=$1
G=$2
REF=$3
out=$4
mkdir -p "$out/logs"
report=$out/report.txt
: > "$report"
top=$PWD
npass=0
nfail=0
nxfail=0

check() {
	local name=$1
	shift
	mkdir -p "$top/work/$name"
	(cd "$top/work/$name" && set -ex && "$@") > "$out/logs/$name.log" 2>&1
	local rc=$?
	if [ $rc = 0 ]; then
		echo "PASS  $name" >> "$report"
		npass=$((npass + 1))
	else
		echo "FAIL  $name (exit $rc)" >> "$report"
		tail -n 40 "$out/logs/$name.log" | sed 's/^/      /' >> "$report"
		nfail=$((nfail + 1))
	fi
}

# A check whose command must fail with a message matching a pattern
xfail() {
	local name=$1 pattern=$2
	shift 2
	mkdir -p "$top/work/$name"
	(cd "$top/work/$name" && "$@") > "$out/logs/$name.log" 2>&1
	local rc=$?
	if [ $rc != 0 ] && grep -q -- "$pattern" "$out/logs/$name.log"; then
		echo "XFAIL $name: $(grep -m1 -- "$pattern" "$out/logs/$name.log")" >> "$report"
		nxfail=$((nxfail + 1))
	else
		echo "FAIL  $name (exit $rc, expected a failure matching '$pattern')" >> "$report"
		tail -n 40 "$out/logs/$name.log" | sed 's/^/      /' >> "$report"
		nfail=$((nfail + 1))
	fi
}

# Haskell 98 programs: GHC 6.2.2 at -O0 and -O, and the reference compiler,
# must print the same
h98() {
	local p=$1
	cp "$src/h98/$p.hs" .
	mkdir o0 o1
	"$G/ghc" -v0 -O0 -odir o0 -hidir o0 --make "$p.hs" -o "$p-O0"
	"$G/ghc" -v0 -O -odir o1 -hidir o1 --make "$p.hs" -o "$p-O1"
	"$REF/ghc" -v0 -O -outputdir ref "$p.hs" -o "$p-ref"
	timeout 300 "./$p-ref" > ref.txt
	# GHC 6.2.2's default stack is 1 MB
	timeout 300 "./$p-O0" +RTS -K256m -RTS > o0.txt
	timeout 300 "./$p-O1" +RTS -K256m -RTS > o1.txt
	cat o1.txt
	diff -u o0.txt o1.txt
	diff -u ref.txt o1.txt
}

# A program with an expected output file, compiled with the given flags
expect() {
	local dir=$1 p=$2
	shift 2
	cp "$src/$dir/$p.hs" .
	"$G/ghc" -v0 "$@" --make "$p.hs" -o "$p"
	timeout 300 "./$p" > out.txt
	diff -u "$src/$dir/$p.out" out.txt
}

t_io() {
	cp "$src/ghc/IO.hs" .
	"$G/ghc" -v0 -O --make IO.hs -o IO
	local rc=0
	printf 'hello world\nsecond\n' | timeout 300 ./IO "a b" c +RTS -K8m -RTS > out.txt 2> err.txt || rc=$?
	cat err.txt
	diff -u "$src/ghc/IO.out" out.txt
	[ "$(cat err.txt)" = "to stderr" ]
	[ $rc = 5 ]
}

t_deadlock() {
	cp "$src/ghc/Deadlock.hs" .
	"$G/ghc" -v0 -O --make Deadlock.hs -o deadlock
	local rc=0
	timeout 60 ./deadlock || rc=$?
	[ $rc = 3 ]
}

t_version() {
	"$G/ghc" --version | grep 'version 6\.2\.2'
	[ "$("$G/ghc" --numeric-version)" = 6.2.2 ]
	test -f "$("$G/ghc" --print-libdir)/package.conf"
	"$G/ghc-pkg" -l | tee pkgs.txt
	for p in base haskell98 haskell-src network parsec QuickCheck unix lang concurrent posix util data text net hssource; do
		grep -Eq "(^|[ ,])$p(,|$)" pkgs.txt
	done
	"$G/ghc-pkg" -s base | grep 'name = "base"'
}

hello() {
	echo 'main = putStrLn "hello"' > Hello.hs
	"$G/ghc" "$@" --make Hello.hs -o hello
	[ "$(./hello)" = hello ]
}

two_modules() {
	printf 'module A (f) where\nf :: Int -> Int\nf x = x * 7\n' > A.hs
	printf 'module Main (main) where\nimport A\nmain :: IO ()\nmain = print (f 6)\n' > Main.hs
}

t_separate() {
	two_modules
	"$G/ghc" -c A.hs
	"$G/ghc" -c Main.hs
	"$G/ghc" -o sep A.o Main.o
	[ "$(./sep)" = 42 ]
	mkdir obj hi
	"$G/ghc" -c -odir obj -hidir hi A.hs
	test -f obj/A.o
	test -f hi/A.hi
	"$G/ghc" --show-iface A.hi > iface.txt 2>&1
	cat iface.txt
	grep -q '^__interface "Main" A ' iface.txt
	grep -q 'f :: ' iface.txt
}

# --make compiles only what changed
t_recomp() {
	two_modules
	"$G/ghc" --make Main.hs -o m > l1.txt 2>&1
	"$G/ghc" --make Main.hs -o m > l2.txt 2>&1
	sleep 1
	echo '-- a comment' >> A.hs
	"$G/ghc" --make Main.hs -o m > l3.txt 2>&1
	sleep 1
	printf 'g :: Int\ng = 1\n' >> A.hs
	sed -i 's/^module A (f) where$/module A (f, g) where/' A.hs
	"$G/ghc" --make Main.hs -o m > l4.txt 2>&1
	cat l1.txt l2.txt l3.txt l4.txt
	[ "$(grep -c '^Compiling' l1.txt)" = 2 ]
	[ "$(grep -c '^Compiling' l2.txt)" = 0 ]
	[ "$(grep -c '^Compiling' l3.txt)" = 1 ]
	[ "$(grep -c '^Compiling' l4.txt)" = 2 ]
	[ "$(./m)" = 42 ]
}

t_modes() {
	two_modules
	"$G/ghc" -M -optdep-f -optdepdeps.mk Main.hs
	cat deps.mk
	grep -Eq '^Main\.o ?: (\./)?A\.hi' deps.mk
	"$G/ghc" -C A.hs
	grep -q 'Stg\.h' A.hc
	"$G/ghc" -S Main.hs
	test -s Main.s
	printf '{-# OPTIONS -cpp #-}\nmodule Main (main) where\nmain :: IO ()\nmain = print (__GLASGOW_HASKELL__ :: Int)\n#if __GLASGOW_HASKELL__ >= 602\n  >> putStrLn "new enough"\n#endif\n' > Cpp.hs
	"$G/ghc" -E Cpp.hs
	ls
	grep -q 602 Cpp.hspp
	"$G/ghc" -v0 --make Cpp.hs -o cpp
	[ "$(./cpp)" = "$(printf '602\nnew enough')" ]
	printf 'module Foo (run) where\nrun :: IO ()\nrun = putStrLn "run from Foo"\n' > Foo.hs
	"$G/ghc" -v0 --make -main-is Foo.run Foo.hs -o foo
	[ "$(./foo)" = "run from Foo" ]
}

t_userpkg() {
	mkdir -p mylib/MyLib
	printf 'module MyLib.Greet (greet) where\ngreet :: String -> String\ngreet n = "greetings, " ++ n\n' > mylib/MyLib/Greet.hs
	(cd mylib && "$G/ghc" -c -package-name mylib MyLib/Greet.hs && ar rcs libHSmylib.a MyLib/Greet.o)
	echo '[]' > local.conf
	cat > mylib.pkg <<EOF
Package { name = "mylib", auto = False, import_dirs = ["$PWD/mylib"], source_dirs = [], library_dirs = ["$PWD/mylib"], hs_libraries = ["HSmylib"], extra_libraries = [], include_dirs = [], c_includes = [], package_deps = ["base"], extra_ghc_opts = [], extra_cc_opts = [], extra_ld_opts = [], framework_dirs = [], extra_frameworks = [] }
EOF
	"$G/ghc-pkg" -f local.conf -a < mylib.pkg
	"$G/ghc-pkg" -f local.conf -l | grep mylib
	printf 'module Main (main) where\nimport MyLib.Greet\nmain :: IO ()\nmain = putStrLn (greet "nix")\n' > UseLib.hs
	"$G/ghc" -v0 -package-conf local.conf -package mylib --make UseLib.hs -o uselib
	[ "$(./uselib)" = "greetings, nix" ]
}

t_exit() {
	printf 'main :: IO ()\nmain = error "fatal problem"\n' > Fail.hs
	"$G/ghc" -v0 --make Fail.hs -o Fail
	local rc=0
	./Fail 2> err.txt || rc=$?
	cat err.txt
	[ $rc = 1 ]
	grep -q '^Fail: fatal problem$' err.txt
	printf 'import System.Exit\nmain :: IO ()\nmain = exitWith (ExitFailure 42)\n' > Exit.hs
	"$G/ghc" -v0 --make Exit.hs -o exit42
	rc=0
	./exit42 || rc=$?
	[ $rc = 42 ]
}

t_rts() {
	printf 'main :: IO ()\nmain = print (foldr (+) 0 [1 .. 1000000 :: Int])\n' > Deep.hs
	"$G/ghc" -v0 -O0 --make Deep.hs -o deep
	local rc=0
	./deep 2> err.txt || rc=$?
	cat err.txt
	[ $rc != 0 ]
	grep -q 'Stack space overflow' err.txt
	[ "$(./deep +RTS -K100m -RTS)" = 500000500000 ]
	./deep +RTS -K100m -sstderr -RTS 2> stats.txt
	cat stats.txt
	grep -q 'bytes allocated' stats.txt
	printf 'main :: IO ()\nmain = let xs = [1 .. 2000000 :: Int] in print (length xs, sum xs)\n' > Heap.hs
	"$G/ghc" -v0 -O0 --make Heap.hs -o heap
	rc=0
	./heap +RTS -M20m -K200m -RTS 2> heap.txt || rc=$?
	cat heap.txt
	[ $rc != 0 ]
	grep -q 'Heap exhausted' heap.txt
	[ "$(./heap +RTS -K200m -RTS)" = "(2000000,2000001000000)" ]
	./deep +RTS -? -RTS > help.txt 2>&1 || true
	grep -q 'Usage:' help.txt
}

t_diagnostics() {
	printf 'main :: IO ()\nmain = putStrLn (1 + True)\n' > TypeErr.hs
	local rc=0
	"$G/ghc" -c TypeErr.hs 2> err.txt || rc=$?
	cat err.txt
	[ $rc != 0 ]
	grep -q '^TypeErr.hs:2' err.txt
	printf 'module Main (main) where\nmain :: IO ()\nmain = print 1\nunused :: Int\nunused = 2\n' > Warn.hs
	"$G/ghc" -Wall -c Warn.hs 2> warn.txt
	cat warn.txt
	grep -q 'not used' warn.txt
	rc=0
	"$G/ghc" -Wall -Werror -c -o werror.o Warn.hs || rc=$?
	[ $rc != 0 ]
}

# A module big enough to stress gcc on the generated C
t_big() {
	{
		echo 'module Main (main) where'
		echo 'import Data.List (foldl'"'"')'
		for i in $(seq 0 1999); do printf 'f%d :: Int -> Int\nf%d x = x + %d\n' $i $i $i; done
		echo 'g :: Int -> Int'
		for i in $(seq 0 999); do printf 'g %d = %d\n' $i $((i * i)); done
		echo 'g _ = -1'
		printf 'main :: IO ()\nmain = do\n  print (foldl'"'"' (+) 0 ['
		for i in $(seq 0 1998); do printf 'f%d 1, ' $i; done
		printf 'f1999 1])\n  print (sum (map g [0 .. 1000]))\n'
	} > Big.hs
	"$G/ghc" -v0 -O --make Big.hs -o big
	[ "$(./big)" = "$(printf '2001000\n332833499')" ]
}

t_hsc2hs() {
	cat > Hsc.hsc <<'EOF'
module Main (main) where

#include <errno.h>
#include <sys/time.h>
#include <time.h>

import Foreign
import Foreign.C

main :: IO ()
main = do
  print (#{size struct timeval} :: Int, #{const EINTR} :: Int, #{const ENOENT} :: Int)
  print (#{offset struct timeval, tv_usec} :: Int)
  allocaBytes #{size struct tm} (\p -> do
    #{poke struct tm, tm_year} p (126 :: CInt)
    y <- #{peek struct tm, tm_year} p :: IO CInt
    print y)
EOF
	"$G/hsc2hs" Hsc.hsc
	cat Hsc.hs
	"$G/ghc" -v0 -fglasgow-exts --make Hsc.hs -o hsc
	[ "$(./hsc)" = "$(printf '(16,4,2)\n8\n126')" ]
}

t_ffi() {
	cp "$src"/ffi/* .
	"$G/ghc" -c cbits.c
	"$G/ghc" -v0 -O -I. --make Ffi.hs cbits.o -o ffi
	./ffi > out.txt
	diff -u Ffi.out out.txt
}

t_export() {
	cp "$src"/ffi/* .
	"$G/ghc" -c -O Exports.hs
	ls
	"$G/ghc" -c cmain.c
	"$G/ghc" -no-hs-main cmain.o Exports.o Exports_stub.o -o fexp
	[ "$(./fexp)" = "42 15" ]
}

t_wrapper() {
	cp "$src"/ffi/Wrapper.hs .
	"$G/ghc" -v0 --make Wrapper.hs -o wrapper
	./wrapper
}

t_tools() {
	two_modules
	"$G/hasktags" A.hs
	ls
	grep -q '^f' tags
}

# gcc -O2 on the generated C, which GHC 6.2.2 compiles with -O by default,
# and with strict aliasing off
t_optc_O2() {
	local p v rc=0
	for p in Integers Arrays; do
		cp "$src/h98/$p.hs" .
		for v in a:-O b:-optc-O2 c:-optc-O2,-optc-fno-strict-aliasing; do
			mkdir -p "${v%%:*}"
			# shellcheck disable=SC2046
			"$G/ghc" -v0 -O $(echo "${v#*:}" | tr , " ") -odir "${v%%:*}" -hidir "${v%%:*}" --make "$p.hs" -o "$p-${v%%:*}"
			"./$p-${v%%:*}" +RTS -K256m -RTS > "$p-${v%%:*}.txt" 2>&1 || echo "exit $?" >> "$p-${v%%:*}.txt"
		done
		diff -u "$p-a.txt" "$p-b.txt" || rc=1
		diff -u "$p-a.txt" "$p-c.txt" || rc=1
	done
	return $rc
}

for p in Integers Floats Text Arrays; do
	check "h98-$p" h98 $p
done
check ghc-Exts expect ghc Exts -O
check ghc-FloatQuirks expect ghc FloatQuirks -O
check ghc-Conc expect ghc Conc -O
check ghc-Exc expect ghc Exc -O
check ghc-Deadlock t_deadlock
check ghc-IO t_io
check lib-Parsec expect lib Parsec -package parsec
check lib-QC expect lib QC -package QuickCheck
check lib-HaskellSrc expect lib HaskellSrc -package haskell-src
check lib-Network expect lib Network -package network
check lib-Unix expect lib Unix -package unix
check lib-Hslibs expect lib Hslibs -package lang -package concurrent -package util -package data -package text -package posix -package net -package hssource
check ffi-imports t_ffi
check ffi-exports t_export
check driver-version t_version
check driver-separate t_separate
check driver-recomp t_recomp
check driver-modes t_modes
check driver-userpkg t_userpkg
check driver-exit t_exit
check driver-rts t_rts
check driver-diagnostics t_diagnostics
check driver-big-module t_big
check driver-hsc2hs t_hsc2hs
check driver-tools t_tools
check driver-optc-O2 t_optc_O2
xfail ffi-wrapper 'adjustor creation not supported' t_wrapper
xfail no-ghci 'not built for interactive use' "$G/ghci"
xfail no-eval 'not built for interactive use' "$G/ghc" -e 'print 1'
xfail no-prof 'Could not find interface file' hello -prof
xfail no-threaded 'cannot find -lHSrts_thr' hello -threaded

echo "$npass passed, $nfail failed, $nxfail expected failures" >> "$report"
cat "$report"
