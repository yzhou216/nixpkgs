# Compares two trees file by file, with store path hashes masked, and prints
# a summary line followed by the paths that differ or exist on one side only.
# For differing text files, a masked diff of the first few follows.
#
# Usage: compare.sh A B LABEL
a=$1
b=$2
label=$3

mask() {
	LC_ALL=C sed -E 's|/nix/store/[0-9a-z]{32}-|/nix/store/HASH-|g'
}

listing() {
	(cd "$1" && find . \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r f; do
		if [ -L "$f" ]; then
			printf '%s link:%s\n' "$f" "$(readlink "$f" | mask)"
		else
			printf '%s %s\n' "$f" "$(mask < "$f" | sha256sum | cut -c1-16)"
		fi
	done)
}

listing "$a" > a.list
listing "$b" > b.list
awk -v label="$label" '
	NR == FNR { h[$1] = $2; next }
	{
		if ($1 in h) {
			if (h[$1] == $2) same++; else { differ++; print "differs: " $1 }
			delete h[$1]
		} else { onlyb++; print "only in B: " $1 }
	}
	END {
		for (k in h) { onlya++; print "only in A: " k }
		printf "%s: %d identical, %d differ, %d only in A, %d only in B\n", label, same, differ, onlya, onlyb
	}' a.list b.list > result.txt
tail -n 1 result.txt
head -n -1 result.txt | LC_ALL=C sort | head -n 200
n=0
for f in $(sed -n 's/^differs: //p' result.txt); do
	if grep -Iq . "$a/$f" 2> /dev/null && [ $n -lt 5 ]; then
		echo "--- masked diff of $f"
		diff -u <(mask < "$a/$f") <(mask < "$b/$f") | head -n 60
		n=$((n + 1))
	elif [ -f "$a/$f" ]; then
		echo "--- $f: $(cmp -l <(mask < "$a/$f") <(mask < "$b/$f") 2> /dev/null | wc -l) bytes differ after masking, sizes $(stat -c %s "$a/$f") and $(stat -c %s "$b/$f")"
	fi
done
