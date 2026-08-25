import { describe, expect, it } from "bun:test";
import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";

const shim = path.join(import.meta.dir, "../scripts/xwin-clang-cl-shim.sh");

describe("cargo-xwin clang-cl shim", () => {
	it("removes the unsupported manifest flag and selects the static CRT", async () => {
		const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "pi-xwin-clang-cl-"));
		const binDir = path.join(tempDir, "bin");
		const capturedArgs = path.join(tempDir, "args");
		try {
			await fs.mkdir(binDir);
			const compiler = path.join(binDir, "clang-cl");
			await Bun.write(compiler, `#!/bin/sh\nprintf '%s\\n' "$@" > "$CAPTURED_ARGS"\n`);
			await fs.chmod(compiler, 0o755);

			const proc = Bun.spawn([shim, "/MD", "/manifest:no", "-MD", "/MDd", "-MT", "source.c"], {
				env: {
					...Bun.env,
					CAPTURED_ARGS: capturedArgs,
					PATH: `${binDir}:${Bun.env.PATH ?? ""}`,
				},
				stdout: "pipe",
				stderr: "pipe",
			});
			expect(await proc.exited).toBe(0);
			expect((await Bun.file(capturedArgs).text()).trim().split("\n")).toEqual([
				"/MT",
				"-MD",
				"/MTd",
				"-MT",
				"source.c",
			]);
		} finally {
			await fs.rm(tempDir, { recursive: true, force: true });
		}
	});
});
