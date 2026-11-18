# Runs a nofib suite (imaginary, spectral or real) with GHC 6.2.2 the way
# nofib's own Makefiles do: each program's compiler flags, arguments, stdin
# and expected output come from its Makefile, read through the stub mk files
# here, and GHC 6.2.2's runstdtest checks the run.
#
# Usage: run.sh NOFIB STUBS RUNSTDTEST GHC SUITE OPT OUT
nofib=$1
stubs=$2
runstdtest=$3
G=$4
suite=$5
opt=$6
out=$7

cp -r "$nofib" nofib
chmod -R u+w nofib
cp "$stubs/boilerplate.mk" "$stubs/target.mk" nofib/mk/
: > nofib/mk/opts.mk
mkdir -p "$out/logs"
report=$out/report.txt
: > "$report"
npass=0
nfail=0

var() {
	sed -n "s/^$1=//p" vars.txt
}

run_prog() {
	local dir=$1 name=$2
	local log=$out/logs/$name
	(
		cd "$dir" || exit 1
		make -s -f Makefile nofib-vars > vars.txt || exit 1
		local prog hc_opts srcs stdin stdouts stderrs rt args main
		prog=$(var prog)
		hc_opts=$(var hc_opts)
		srcs=$(var srcs)
		stdin=$(var stdin)
		stdouts=$(var stdout)
		stderrs=$(var stderr)
		rt=$(var runtest_opts)
		args=$(var args)
		cat vars.txt > "$log.vars"
		if [ -f Main.hs ]; then
			main=Main.hs
		elif [ -f Main.lhs ]; then
			main=Main.lhs
		else
			main=$srcs
		fi
		# shellcheck disable=SC2086
		if ! timeout 3600 "$G/ghc" $opt $hc_opts -i. --make $main -o "$prog" > "$log.build" 2>&1; then
			echo build > status
			exit 0
		fi
		local o1=() o2=() f
		for f in $stdouts; do o1+=(-o1 "$f"); done
		for f in $stderrs; do o2+=(-o2 "$f"); done
		# shellcheck disable=SC2086
		if timeout 1800 perl "$runstdtest" "./$prog" ${stdin:+-i "$stdin"} "${o1[@]}" "${o2[@]}" $rt $args > "$log.run" 2>&1; then
			echo pass > status
		else
			echo run > status
		fi
	)
	local st
	st=$(cat "$dir/status" 2>/dev/null || echo setup)
	if [ "$st" = pass ]; then
		echo "PASS  $name" >> "$report"
		npass=$((npass + 1))
	else
		echo "FAIL  $name ($st)" >> "$report"
		for f in "$log.build" "$log.run"; do
			[ -f "$f" ] && tail -n 25 "$f" | sed 's/^/      /' >> "$report"
		done
		nfail=$((nfail + 1))
	fi
}

walk() {
	local dir=$1 name=$2 subdirs d
	subdirs=$(cd "$dir" && make -s -f Makefile nofib-vars | sed -n 's/^subdirs=//p')
	if [ -n "$subdirs" ]; then
		for d in $subdirs; do
			walk "$dir/$d" "$name${name:+-}$d"
		done
	else
		run_prog "$dir" "$name"
	fi
}

walk "nofib/$suite" ""
echo "$suite $opt: $npass passed, $nfail failed" >> "$report"
cat "$report"
