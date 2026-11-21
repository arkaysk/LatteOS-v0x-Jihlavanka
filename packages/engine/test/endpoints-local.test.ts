import { describe, expect, test } from "bun:test";
import { onThisComputer } from "../src/endpoints";

// LatteOS (ADR 0202): a server on this computer gets its models tested one after another
describe("onThisComputer", () => {
  test("loopback addresses are this computer", () => {
    expect(onThisComputer("http://127.0.0.1:8790/v1")).toBe(true);
    expect(onThisComputer("http://localhost:11434")).toBe(true);
    expect(onThisComputer("http://[::1]:8790")).toBe(true);
  });
  test("anything else is not", () => {
    expect(onThisComputer("https://api.example.com/v1")).toBe(false);
    expect(onThisComputer("http://192.168.1.5:8790")).toBe(false);
    expect(onThisComputer("not a url")).toBe(false);
  });
});

import { isLatteosLocal, latteosLocalModels, latteosLocalProgress, setLatteosConfig } from "../src/latteos";

describe("LatteOS's own models", () => {
  setLatteosConfig({
    mcpUrl: "http://127.0.0.1:8791",
    mcpTokenFile: "/dev/null",
    localLlmUrl: "http://127.0.0.1:8790/v1",
  });
  const fake = (body: unknown) => (async () => new Response(JSON.stringify(body))) as unknown as typeof fetch;
  test("the key of this computer's models is known by its address", () => {
    expect(isLatteosLocal("http://127.0.0.1:8790/v1")).toBe(true);
    expect(isLatteosLocal("http://127.0.0.1:11434/v1")).toBe(false);
  });
  test("every downloaded model is listed, a bad name left out", async () => {
    const got = await latteosLocalModels({
      token: () => "t",
      fetch: fake([
        { id: "Qwen3.5-4B-Q4_K_M", label: "Qwen3.5 4B · Q4_K_M · 2.7 GB", tools: true },
        { id: "../etc/passwd", label: "x" },
      ]),
    });
    expect(got?.map((m) => m.id)).toEqual(["Qwen3.5-4B-Q4_K_M"]);
    expect(got?.[0]?.tools).toBe(true);
  });
  test("loading is told with its percent, kept within 0–100", async () => {
    const got = await latteosLocalProgress("Qwen3.5-4B-Q4_K_M", {
      token: () => "t",
      fetch: fake({ state: "loading", percent: 140 }),
    });
    expect(got).toEqual({ state: "loading", percent: 100 });
    expect((await latteosLocalProgress("a b", { token: () => "t", fetch: fake({}) })).state).toBe("none");
  });
});
