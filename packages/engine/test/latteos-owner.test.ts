// LatteOS (security audit S8): this computer's MCP servers only for the workspace its runner is paired with.
import { afterAll, expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { latteosOwnsOrg, setLatteosConfig } from "../src/latteos";

const dir = mkdtempSync(`${tmpdir()}/latteos-owner-`);
afterAll(() => {
  setLatteosConfig({});
  rmSync(dir, { recursive: true, force: true });
});

test("only the paired workspace, any while nothing is paired", () => {
  setLatteosConfig({ runnerConfig: `${dir}/config.json` });
  expect(latteosOwnsOrg("org-a")).toBe(true); // not paired yet
  writeFileSync(`${dir}/config.json`, JSON.stringify({ orgId: "org-a" }));
  expect(latteosOwnsOrg("org-a")).toBe(true);
  expect(latteosOwnsOrg("org-b")).toBe(false);
  writeFileSync(`${dir}/config.json`, "not json");
  expect(latteosOwnsOrg("org-a")).toBe(false);
  setLatteosConfig({});
  expect(latteosOwnsOrg("org-b")).toBe(true); // unset: as an unforked server
});
