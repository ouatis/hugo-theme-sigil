# AGENTS.md

Notes for AI agents working on this repository. Humans: the README is your
entry point; this file is the maintainer's cheat sheet.

## What this is

SIGIL — a restrained literary blog theme for Hugo (≥ 0.166), deep fork of
[PaperMod](https://github.com/adityatelange/hugo-PaperMod). The MIT license
and the PaperMod attribution chain in `LICENSE` / `NOTICE.md` must survive
every change.

## Build & verify

```bash
# interactive preview
cd exampleSite && hugo server --themesDir ../..

# one-shot verification (clears caches, builds with --minify, asserts artifacts)
bash scripts/check.sh
```

A clean exit from `scripts/check.sh` is the definition of "works". Run it
before proposing any change. CI (`.github/workflows/demo.yml`) builds
exampleSite for the demo site; fonts are regenerated there on every deploy.

Pull requests run the same build, `check.sh`, the negative suite and a browser
smoke — but against their own output, served on localhost, and they never
deploy, prune runs or open tickets. The two install jobs in
`install-modes.yml` stay main-only on purpose: they clone this repository by
URL, which resolves to the default branch, so on a PR they would test main and
report green for a change nobody installed. Any new workflow step that writes
to the repository (deploy, issue, run deletion) must carry
`if: github.event_name != 'pull_request'`.

`build` pins the floor: the Hugo `min_version` in `theme.toml`, i.e. what an
install that has not been touched in a year still runs. The separate
`hugo-latest` job runs the same `check.sh` + negative suite on the newest Hugo
release, because Hugo has broken themes across minors and a user gets the new
binary the day it ships — that break must land in CI, not in an issue.

`scripts/smoke.sh` is the browser half of the same contract, and it needs
Playwright, `axe-playwright-python` and a served build, so it runs in CI: it
covers 17 routes — every language home, typography and docs page, plus the
pages only reachable through links (archives, the tag list, a tag term, about,
api, config-example, the 404 and a `?q=` search) — and proves what no static
check can see: KaTeX actually rendered, sidenote markers exist, a search
renders a visible hit from `index.json`, no page logs a console error, and
axe-core finds **no** violations with either palette forced on `<html>`
(34 audits per run). A route that answers 200 with an empty `<main>` still
fails, because the page's selector is asserted to exist. Static output can be
green while all of that is broken.

axe is injected from the Python package (`python -m pip install
axe-playwright-python`), not from a vendored 550 KB `axe.min.js`: the theme
does not ship an audit script, and CI installs the wheel in both the PR and the
post-deploy smoke steps.

`check.sh` also treats the **machine-readable output as a contract**, not just
"the file exists": RSS dates must parse as RFC 822 and every channel must
carry `atom:link rel=self`; `feed.json` must be JSON Feed 1.1 with unique
item ids and RFC 3339 dates; every JSON-LD block must carry an id
(`ld-org` on a homepage, `ld-breadcrumb`/`ld-post` on a post), `json.loads`,
and a schema.org `@context`, and a BlogPosting must carry a numeric `wordCount`
(schema.org types it Integer, so a quoted count is a validator warning);
every `target=_blank` must have
`noopener noreferrer` in `rel`; every external link in post content must
carry `sg-ext` and no internal one may; `llms-full.txt` must exist, be larger
than `llms.txt`, and carry one `## <title>` section per post that `llms.txt`
lists; no built JS bundle may contain `console.log`; every `index.json` must
parse as a JSON array of entries carrying `title`, `content`, `permalink`,
`summary`, `date`, `category` and `readingtime`, with absolute unique
permalinks and no HTML entity left in `content` (search indexes the text, so
`theme&rsquo;s` never matches a query for `theme's`); and a build with
`ShowFullTextinRSS` turned on must still parse as XML with every item that has
a summary also carrying `<content:encoded>` full text.
`scripts/check-contracts-negative.py` proves those
assertions actually bite by mutating a built `public/` copy (run
`bash scripts/check.sh` first, then `python scripts/check-contracts-negative.py`)
— extend it whenever you add an assertion, otherwise the new check is
unverified. Both parsers read decoded text: never grep raw HTML for these,
see Pitfall 7. Write every string in a JSON-LD block as
`{{ ... | jsonify | safeJS }}`: without it Go's JS context escaper and the
hand-quoted fields disagree, and the same quote is emitted as `\"`, `\u0022`
or `\u0026quot;` depending on the field. The output happened to parse; nothing
guaranteed it would keep parsing. See Pitfall 9.

Environment: Hugo 0.166 is the floor (`theme.toml`'s `min_version`) and what
`build` runs; `hugo-latest` builds on the newest release (0.169 when this was
written) — when a template change is involved, run both.

Font tooling needs a real python3 with
fonttools + brotli. On Windows `python3` is often the Microsoft Store stub:
it exists on PATH but every call exits 49 with no output, so `command -v`
proves nothing. `scripts/lib-python.sh` resolves an interpreter by actually
running it (`SG_PYTHON` if set, else `python3`, else `python`); every script
sources it and then uses `"$SG_PY"`. Set `SG_PYTHON` to an absolute path to
pin a specific interpreter — an unusable value is a hard error, never a
silent fallback. In Git Bash, PATH entries must use POSIX form (`/c/...`); a
`C:/...` entry silently does not take effect. Never pipe a foreground
`hugo server` into `head` (SIGPIPE kills it).

## CI

Five workflows, each carrying a different half of "works":

| Workflow | Job | Runs on | Proves |
| --- | --- | --- | --- |
| `demo.yml` | `build` | push main / PR / dispatch | `check.sh` + negative suite; deploys Pages on main, then smokes the live site |
| `demo.yml` | `hugo-latest` | push main / PR / dispatch | the same suite on the newest Hugo release |
| `install-modes.yml` | submodule / module | main only | a clean install renders (they clone this repo by URL, so on a PR they would test main) |
| `install-modes.yml` | resource-integrity | push main / PR | every committed CSS `@import` target exists in the checkout |
| `compatibility.yml` | zero-config | push main / PR / dispatch | a fresh `hugo new site` with only `theme = "hugo-theme-sigil"` and one post renders |
| `compatibility.yml` | api-contract | push main / PR / dispatch | no identifier frozen in `docs/api.md` disappeared since the committed baseline snapshot |
| `workflow-lint.yml` | actionlint | push main / PR | the workflows themselves: event wiring, expressions, `run:` shell |

`zero-config` exists because `exampleSite` cannot answer that question: it
carries its own config, fonts and content, so it stays green while the
first-install path is broken. `api-contract` exists because renaming an
`sg…` param usually looks like a documentation edit — no build notices, and
the deprecation policy in `docs/api.md` promises the opposite. Additions pass;
surviving identifiers are printed as a count.

Every step that writes to the repository (deploy, run pruning, failure
tickets) carries `if: github.event_name != 'pull_request'`.

Two version strings are hand-maintained, because Dependabot cannot see them:

- the Hugo pins: `0.166.0` is the floor and must stay equal to `theme.toml`'s
  `min_version`; the `0.169.0` in `hugo-latest` should track the newest
  release. Bump it when Hugo ships.
- the actionlint download URL in `workflow-lint.yml`.

Everything else — the action tags — arrives as a weekly Dependabot PR
(`.github/dependabot.yml`) and is verified by the PR pipeline before merging.

`main` rejects force pushes and deletion (no required checks: direct pushes
still work). Losing that protection means a `--force` can rewrite history
someone already cloned.

## Map

- `assets/css/extended/sigil.css` — the design layer (palette, typography,
  components). `assets/css/core/theme-vars.css` — legacy PaperMod color vars.
- `assets/css/extended/` — the **concat contract**: `head.html` concatenates
  the theme's own `sigil.css`/`fonts.css` FIRST, then every site-level
  `css/extended/*.css` LAST. Site overrides always win ties. Do not fix
  specificity with `html:root` hacks — the concat order is the mechanism.
- `layouts/partials/templates/` — OG / Twitter / Schema partials. Call
  partials with the FULL path (`templates/_funcs/get-page-images`); short
  names resolve inconsistently and broke og:image silently once.
- Site override points (never edit core templates to customize):
  `extend_head.html`, `extend_footer.html`, `comments.html` (built-in giscus
  when `[params.giscus]` + `comments` are set; shadow it for any other
  comment system), render hooks under `_default/_markup/`, anything in the
  site's `layouts/` or `assets/css/extended/`.

## Page parameter contract (for content generators)

Front matter or site params the theme reads:

| Param | Effect |
| --- | --- |
| `math` / `mermaid` / `lightbox` | opt-ins; nothing loads on pages that don't set them |
| `ogAutoCard` | build-time OG card from title (needs `ogCardFont` on CJK sites) |
| `showRelated` | related-posts block (default on) |
| `cover.image` / `cover.relative` | cover image, supersedes the OG card |
| `searchHidden`, `placeholder` | search index exclusion / search input placeholder |
| `hiddenInHomeList` | keep a post out of the homepage feed |
| `sgSeriesFrom`, `sgSeriesTab` | series navigation (site-level) |
| `archives.showAuthor` | author on archive rows (default off) |
| `comments` + `[params.giscus]` | built-in giscus comments (off by default, zero requests); front matter `comments: false` opts a page out |

SIGIL-specific site params use the `sg*` prefix (`sgKicker`, `sgHomeTitle`,
`sgReading`, `sgPlaying`, `sgMotto`, `sgSealImage`, `sgDaysInCage`,
`sgSearchEmpty`, `sgSeriesFrom`, `sgSeriesTab`). Inherited PaperMod params
keep their names.

## Pitfalls (each cost a real debugging session)

1. **Hugo's processed-image cache (`resources/_gen`) does not key on
   `images.Text` font bytes.** After changing any font, `rm -rf resources`
   before trusting a local pass — stale cache produces green builds that are
   lies.
2. **pyftsubset output flavor defaults to the input's.** Subsetting a
   `.woff2` into a `.ttf` filename still writes `wOF2` bytes, which Go's
   sfnt parser rejects (`sfnt: invalid font`). Use `--flavor=none`.
3. **goldmark passthrough config key is `enable`, not `enabled`** — wrong key
   is a silent no-op, inline `\(...\)` math then gets eaten by markdown.
4. **Partial names must be full paths** from `partials/`, including the
   `templates/` prefix.
5. **IBM Plex has no U+2234 (∴) glyph** — the OG card's mark is baked into
   `assets/og/base.png`; don't try to draw it with `images.Text`.
6. **`check.sh` asserts uncommitted `static/fonts/` artifacts** — fresh
   clone: `bash scripts/build-fonts.sh corpus` first; a failed download
   wipes `static/fonts/` (`git checkout -- static/` restores).
7. **Never grep raw HTML/XML for date or URL formats.** Hugo escapes `+` in
   a `+0000` RSS offset to `&#43;0000` without `--minify` (and leaves it
   alone with it), so a regex run over the raw bytes passes or fails on a
   build flag. Parse with `xml.etree` / `html.parser` and assert on decoded
   text. Likewise `--minify` drops attribute quotes (`class=sg-ext`), so
   attribute matching must use a parser or tolerate both forms.
8. **Python output in `check.sh` needs `PYTHONIOENCODING=utf-8`.** Without it
   Python encodes stdout with the console codepage (cp936 on Chinese Windows)
   and every em dash or CJK menu word in a failure message arrives as `??`.
   The script exports it right after resolving the interpreter; keep that
   export ahead of any heredoc that prints non-ASCII.

### 9. `llms-full.txt` was documented before it was built

`layouts/home.llmsfull.txt` and the `llms.txt` header link both shipped, but
`exampleSite/hugo.toml` never listed `LLMSFULL` in `[outputs] home`, so the
file the README advertised was never generated — and nothing failed. Both the
output and the assertion now exist. If you add an output format, add it to the
demo config the same day; a template with no output is invisible.

`plainify` alone is not enough for that file: it strips tags but leaves entities
(`&#34;`, `&rsquo;`, `&#x21a9;`), so agents would read markup instead of prose.
The template pipes the body through `htmlUnescape` after `plainify`.

### 10. JSON-LD strings: `jsonify | safeJS`, never hand-quoted

Inside a `<script>` block Go treats interpolations as JavaScript, so
`"name": {{ .Title }}` and `"name": "{{ .Title }}"` take different escaper
paths and produce different bytes for the same quote. Values are now
`{{ ... | jsonify | safeJS }}`; jsonify emits a complete JSON value (quotes
included) and safeJS stops the second escape pass. Keep `plainify` before it
and `htmlUnescape` after `plainify` — otherwise `&rsquo;` and `&#34;` survive
into the JSON as literal entity text.

### 11. An undeclared XML namespace made every feed unreadable

`layouts/home.rss.xml` emitted `<content:encoded>` while declaring only
`xmlns:atom`. `content:` has no default namespace, so the whole document
became unparseable ("unbound prefix") for readers the moment
`ShowFullTextinRSS` was on — and the home feed is the one most people
subscribe to. `layouts/_default/rss.xml` (section feeds) had declared it all
along, which is why only the home feed broke.

Nothing caught it because the demo never enabled the flag: check.sh parsed the
feeds that existed, and the full-text branch never existed in any build. The
demo now builds a throwaway config with the gate on
(`exampleSite/hugo.fulltext-check.toml`, removed afterwards) and parses every
feed it produces; `check-contracts-negative.py` deletes the namespace and
demands a failure. Two rules fall out: declare the namespace in the same edit
that emits the prefixed element, and build every opt-in feature at least once
in CI — an unbuilt branch is indistinguishable from a working one.

### 12. axe reports contrast failures that are really mid-transition snapshots

The `color` transition on links and the theme's fade-in meant axe sampled a
half-faded colour and reported `color-contrast` for elements that are fine at
rest (one `.sg-ext > code` node measured 3.97 only because it was 250 ms into a
fade). Inject `*, *::before, *::after { transition: none !important;
animation: none !important; }` **before** the first audit and let the document
settle; otherwise the suite fails on timing, not on design.

Two real failures hid behind that noise, and both were invisible in one palette
only: the Catppuccin comment colour `#6e738d` sits at 3.54:1 on the light code
block and 4.01:1 on the dark one (now `#858ba1`, 4.88:1, with a darker print
override because paper uses a `#f5f5f5` block), and the dark `--sg-green`
`#5f876f` was 4.08:1 on `--entry` (now `#6d977f`). Auditing one theme would
have shipped both. A third class, `heading-order`, has no colour: the search
page rendered `<h3>` hits under an `<h1>`, so it now carries a visually hidden
`<h2>` wired to the list with `aria-labelledby` — the entry markup and its CSS
stayed untouched.

The fourth was `region`, and it appeared only after deployment. Cloudflare
adds a hidden anchor before the theme's first body child; that extra DOM node
made axe classify the otherwise valid, fixed `.skip-link` as outside a
landmark. Reproduce third-party injections locally when an audit differs
between the built site and the deployed site. The skip link now lives in its
own zero-height `nav`; putting it in `header` would change its fixed-position
containing block because this theme transforms the header.

### 13. A heredoc inside a YAML `run: |` block inherits the block's indentation

Writing a test page from a workflow step with a heredoc produced a
`hello.md` whose front matter was indented ten spaces, and Hugo answered
`failed to create page from pageMetaSource /posts/hello: "…hello.md:2:1": EOF
looking for end YAML front matter delimiter`. `run: |` keeps the block's
indentation in the script text, and bash strips it only from the command
lines it parses — not from a heredoc body, whose lines must be flush left.
Keep heredoc bodies in `scripts/ci/*.sh` (or emit them with `printf`) and let
the workflow call the script.

### 14. The frozen API is enforced by identifiers, not by a diff of prose

`docs/api.md` is the public contract, and a review of the prose misses a
rename: the paragraph still reads well, the build still passes, and a user's
`sgKicker = …` silently stops doing anything. `scripts/ci/check-api-identifiers.py`
extracts every backticked identifier from the current file and from
`scripts/ci/api-baseline.json`, and fails only when one **disappeared** —
additions are allowed, because the policy permits new params with docs.

The baseline is a committed snapshot, not a git tag, because tags are not
stable: the 2026-11-03 history rewrite moved every tag onto the new root
commit, so `git show v0.12.0:docs/api.md` now returns the current document and
the check compared the file with itself — green forever, for the one thing it
exists to catch. The snapshot carries the source tag and commit it was taken
from (`v0.12.0`, `45ef3cf`), and a missing or empty snapshot is a hard error,
never a silent pass. Regenerate it only to raise the frozen surface, never to
absorb an identifier that just vanished; `--source git` remains for ad-hoc
comparisons against another ref.

## Conventions

- i18n: strings go through `i18n "key" | default "English"`; fill
  `en`, `zh-CN`, `zh`, `ja`; the other ~45 languages fall back gracefully.
- Third-party code gets vendored only with an attribution note in
  `NOTICE.md`. Vendoring is the default even for large files: since
  2026-11-03 the diagram engine ships vendored too (Pele, 734 KB), so a
  page that enables a feature makes no third-party request. If something is
  ever too large to vendor, pin the CDN with SRI and record it in
  `NOTICE.md` and the PR.
- exampleSite keeps **exactly three posts**. Feature demos fold into
  `posts/typography/` (which enables math + mermaid + lightbox); do not add
  pages.
- New features are opt-in per page or site, and load nothing when disabled.

## Public contract

`docs/api.md` is the frozen public API (params, `sg-*` classes, output
formats, data shapes) as of v0.12.0. Renames need a deprecation window;
removals wait for a major. Check it before touching any param or class name.

## v1.0.0 gate (defined 2026-10-24)

v1.0.0 is a stability statement, not a feature list. All three must hold:

- [ ] **Two weeks without a regression**, counted from 2026-11-02
      (→ 2026-11-16): Demo / Install modes / Compatibility stay green and no
      `fix:` commit lands on `main`. A regression resets the clock from its
      fix. Pure additive releases (new opt-in params with docs + check
      coverage) and maintenance commits (`ci:` / `docs:` / `test:`) do **not**
      reset it.
- [ ] **Gallery healthy**: no new red items from the hugoThemesSiteBuilder
      checker, and the themes.gohugo.io card reflects the current tag.
- [ ] **Contract intact**: `scripts/ci/check-api-identifiers.py` passes — no
      identifier recorded in `scripts/ci/api-baseline.json` has disappeared
      from `docs/api.md`; additions are fine (with a doc row each).

When all three hold: annotated tag `v1.0.0`, release notes from the tag
message.
