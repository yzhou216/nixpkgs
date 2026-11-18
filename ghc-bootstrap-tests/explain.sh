# Shows where two builds of GHC 6.2.2 differ: the bytes of the compiler binary,
# with the section and nearest symbol of each, and the differing interfaces,
# as `ghc --show-iface` prints them.
#
# Usage: explain.sh A B
a=$1
b=$2
bin=lib/ghc-6.2.2/ghc-6.2.2

echo "== $bin: differing bytes (offset, A, B, section, symbol)"
objdump -h -w "$a/$bin" | awk '$2 ~ /^\./ { print $2, $3, $4, $6 }' > sections.txt
nm -n "$a/$bin" > syms.txt
cmp -l "$a/$bin" "$b/$bin" | head -n 40 | while read -r off x y; do
	off=$((off - 1))
	read -r sec addr < <(awk -v o="$off" '{
		size = strtonum("0x" $2); vma = strtonum("0x" $3); fo = strtonum("0x" $4)
		if (o >= fo && o < fo + size) { printf "%s %d\n", $1, vma + o - fo; exit }
	}' sections.txt)
	sym=$(awk -v a="${addr:-0}" '{ v = strtonum("0x" $1); if (v <= a) s = $3 " +" (a - v); else exit } END { print s }' syms.txt)
	printf '%#x %s %s %s %s\n' "$off" "$x" "$y" "${sec:-?}" "$sym"
done

for hi in $(cd "$a/lib/ghc-6.2.2/imports" && find . -name '*.hi' | sort); do
	if ! cmp -s "$a/lib/ghc-6.2.2/imports/$hi" "$b/lib/ghc-6.2.2/imports/$hi"; then
		echo "== $hi"
		diff <("$b/bin/ghc" --show-iface "$a/lib/ghc-6.2.2/imports/$hi" 2>&1) \
			<("$b/bin/ghc" --show-iface "$b/lib/ghc-6.2.2/imports/$hi" 2>&1) | head -n 40
	fi
done
