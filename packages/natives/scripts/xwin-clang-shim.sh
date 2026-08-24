#!/bin/sh
# cargo-xwin compiles C/C++ with clang-cl and injects MSVC `/imsvc <dir>`
# include flags into CFLAGS. ring 0.17's aarch64-windows build.rs then
# force-switches those units to the GNU `clang` driver for `.S` assembly.
# GNU clang treats `/imsvc` as an input path ("no such file or directory:
# '/imsvc'"). Rewrite each token to `-isystem` and exec the real clang.
# clang-cl is a different basename and is not shadowed.
set -eu
self_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
real=""
IFS=:
for d in $PATH; do
	[ "$d" = "$self_dir" ] && continue
	if [ -x "$d/clang" ]; then
		real="$d/clang"
		break
	fi
done
unset IFS
[ -n "$real" ] || {
	echo "xwin-clang-shim: real clang not found on PATH" >&2
	exit 127
}

n=0
for a in "$@"; do
	case "$a" in
	/imsvc)
		eval "arg_$n=-isystem"
		n=$((n + 1))
		;;
	/imsvc*)
		rest=${a#/imsvc}
		eval "arg_$n=-isystem"
		n=$((n + 1))
		eval "arg_$n=\$rest"
		n=$((n + 1))
		;;
	*)
		eval "arg_$n=\$a"
		n=$((n + 1))
		;;
	esac
done

i=0
set --
while [ "$i" -lt "$n" ]; do
	eval "v=\$arg_$i"
	set -- "$@" "$v"
	i=$((i + 1))
done
exec "$real" "$@"
