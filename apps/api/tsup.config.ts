import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/index.ts"],
  outDir: "dist",
  format: ["cjs"],
  platform: "node",
  target: "node20",
  sourcemap: true,
  clean: true
});
