#!/usr/bin/env bash
# cargo-xwin's CMake toolchain assumes clang-cl accepts `/manifest:no`, but
# Ubuntu 22.04's LLVM 14 GNU driver rejects it as a pathname. The flag only
# suppresses manifest embedding for CMake's throwaway try-compile executable,
# so remove it. `/MD` is the MSVC dynamic-CRT switch; `-MD`/`-MT` are GNU
# dependency-file options and must pass through unchanged.
set -euo pipefail

self_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
real=""
IFS=: read -r -a path_dirs <<< "${PATH:-}"
for dir in "${path_dirs[@]}"; do
	[[ "$dir" == "$self_dir" ]] && continue
	if [[ -x "$dir/clang-cl" ]]; then
		real="$dir/clang-cl"
		break
	fi
done
[[ -n "$real" ]] || {
	echo "xwin-clang-cl-shim: cargo-xwin clang-cl not found on PATH" >&2
	exit 127
}

args=()
for arg; do
	case "$arg" in
	/manifest:no) ;;
	/MD) args+=("/MT") ;;
	/MDd) args+=("/MTd") ;;
	*) args+=("$arg") ;;
	esac
done
exec "$real" "${args[@]}"
