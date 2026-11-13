#!/usr/bin/env node
/**
 * WCAG contrast audit for Sigil's palette.
 *
 * Sigil's colors are literal hex values in two mode blocks (.theme-light /
 * .theme-dark) of sigil.css — no token graph to resolve. The audit reads the
 * two blocks, computes WCAG 2.x ratios for a fixed matrix of role pairs, and
 * fails the run when a pair drops below its locked threshold: the point is to
 * catch regressions (a "slightly softer" gray that quietly breaks a role),
 * not to grade the design. Thresholds below lock the palette as of v0.9.19.
 *
 * Usage: node scripts/audit-contrast.mjs [--verbose]
 * Exits 1 when any pair falls below threshold.
 */

import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const verbose = process.argv.includes("--verbose");
const here = fileURLToPath(new URL(".", import.meta.url));
const css = await readFile(here + "../assets/css/extended/sigil.css", "utf8");

function block(selector) {
  const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const re = new RegExp(`${esc(selector)}\\s*\\{([^}]*)\\}`);
  const m = css.match(re);
  if (!m) throw new Error(`block not found: ${selector}`);
  const out = {};
  for (const mm of m[1].matchAll(/--([a-z0-9-]+)\s*:\s*(#[0-9a-fA-F]{3,8})\s*;/g)) {
    out[mm[1]] = mm[2];
  }
  return out;
}

const light = block(":root"); // 首个 :root 即亮色基线(调色盘+布局变量)
const dark = block(':root[data-theme="dark"]');

function rgb(hex) {
  let h = hex.replace("#", "");
  if (h.length === 3) h = [...h].map((c) => c + c).join("");
  return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
}
function lum([r, g, b]) {
  const f = (c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
}
function ratio(fg, bg) {
  const [a, b] = [lum(fg), lum(bg)].sort((x, y) => y - x);
  return (a + 0.05) / (b + 0.05);
}

/* role pairs: [mode, fg token, bg token, min ratio, label]
   阈值即契约:调色盘有意变淡时,先改这里再改色值,审过才算数。 */
const PAIRS = [
  ["light", "primary", "theme", 4.5, "正文 / 纸面"],
  ["light", "primary", "entry", 4.5, "正文 / 卡面"],
  ["light", "secondary", "theme", 4.5, "次级文本 / 纸面"],
  ["light", "sg-red", "theme", 4.0, "链接朱砂"],
  ["light", "sg-green", "theme", 4.0, "类别墨绿"],
  ["dark", "primary", "theme", 4.5, "正文 / 夜幕"],
  ["dark", "primary", "entry", 4.5, "正文 / 卡面"],
  ["dark", "secondary", "theme", 4.5, "次级文本 / 夜幕"],
  ["dark", "sg-red", "theme", 3.0, "链接朱砂(暗)"],
  ["dark", "sg-green", "theme", 3.0, "类别墨绿(暗)"],
];

let fail = 0;
for (const [mode, fg, bg, min, label] of PAIRS) {
  const t = mode === "light" ? light : dark;
  if (!t[fg] || !t[bg]) {
    console.log(`UNRESOLVED  ${mode} ${fg} on ${bg} — token missing`);
    fail++;
    continue;
  }
  const r = ratio(rgb(t[fg]), rgb(t[bg]));
  const ok = r >= min;
  if (!ok) fail++;
  if (!ok || verbose) {
    console.log(`${ok ? "ok " : "LOW"}  ${mode}  ${fg} on ${bg}: ${r.toFixed(2)}:1 (min ${min}) — ${label}`);
  }
}
console.log(fail ? `contrast audit: FAIL (${fail} pair${fail > 1 ? "s" : ""} below threshold)` : "contrast audit: all green");
process.exit(fail ? 1 : 0);
