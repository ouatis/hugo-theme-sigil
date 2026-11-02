#!/usr/bin/env python3
"""Negative tests for the check.sh contract blocks.

Extracts each heredoc block from scripts/check.sh, runs it against a pristine
copy of exampleSite/public (must pass), then against mutated copies (must fail).
"""
import glob as glob_mod
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECK = os.path.join(REPO, "scripts", "check.sh")
PUBLIC = os.path.join(REPO, "exampleSite", "public")
PY = sys.executable

# check.sh emits UTF-8; mirror that so failure excerpts are readable here too.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def blocks():
    """Return [(first_line_number, code)] for every python heredoc in check.sh."""
    lines = io.open(CHECK, encoding="utf-8").read().splitlines()
    out = []
    i = 0
    while i < len(lines):
        if lines[i].endswith("<<'PY'"):
            start = i + 1
            j = start
            while lines[j] != "PY":
                j += 1
            out.append((start + 1, "\n".join(lines[start:j]) + "\n"))
            i = j
        i += 1
    return out


def run(code, workdir, env_extra=None):
    env = dict(os.environ)
    env["SG_THEME_ROOT"] = REPO
    env["PYTHONIOENCODING"] = "utf-8"  # same as check.sh: readable failure text
    if env_extra:
        env.update(env_extra)
    return subprocess.run([PY, "-c", code], cwd=workdir, env=env,
                          capture_output=True, text=True,
                          encoding="utf-8", errors="replace")


def mutate_read(path, old, new):
    text = io.open(path, encoding="utf-8").read()
    assert old in text, "mutation target missing in %s" % path
    io.open(path, "w", encoding="utf-8", newline="").write(text.replace(old, new, 1))


def main():
    feed_code = None
    meta_code = None
    llms_code = None
    assets_code = None
    for lineno, code in blocks():
        if "JSON Feed" in code and "pubDate" in code:
            feed_code = code
        if "ld+json" in code and "noopener" in code:
            meta_code = code
        if "llms-full" in code and "All posts" in code:
            llms_code = code
        if "console.log" in code and "assets/js" in code:
            assets_code = code
    assert feed_code and meta_code and llms_code and assets_code, (
        "could not locate all four blocks: "
        f"feed={bool(feed_code)} meta={bool(meta_code)} "
        f"llms={bool(llms_code)} assets={bool(assets_code)}"
    )

    failures = []

    def expect(name, ok, detail=""):
        print(("  PASS  " if ok else "  FAIL  ") + name + (("  " + detail) if detail else ""))
        if not ok:
            failures.append(name)

    with tempfile.TemporaryDirectory() as tmp:
        base = os.path.join(tmp, "public")
        shutil.copytree(PUBLIC, base)

        print("feeds block")
        r = run(feed_code, tmp)
        expect("clean public passes", r.returncode == 0, r.stdout.strip()[-80:])

        # 1. bad pubDate
        candidates = sorted(
            os.path.join(dp, f)
            for dp, _, fs in os.walk(os.path.join(tmp, "public"))
            for f in fs if f == "index.xml"
        )
        bad = next((c for c in candidates
                    if "<pubDate>" in io.open(c, encoding="utf-8").read()), None)
        assert bad, "no RSS feed with items found"
        orig = io.open(bad, encoding="utf-8").read()
        mutated = re.sub(r"<pubDate>[^<]+</pubDate>", "<pubDate>yesterday</pubDate>", orig, count=1)
        io.open(bad, "w", encoding="utf-8", newline="").write(mutated)
        r = run(feed_code, tmp)
        expect("bad pubDate fails", r.returncode != 0, r.stderr.strip().splitlines()[-1][:90] if r.stderr.strip() else "")
        io.open(bad, "w", encoding="utf-8", newline="").write(orig)

        # 2. missing atom:link self
        mutated = re.sub(r'<atom:link[^>]*/>', "", orig, count=1)
        io.open(bad, "w", encoding="utf-8", newline="").write(mutated)
        r = run(feed_code, tmp)
        expect("missing atom:self fails", r.returncode != 0)
        io.open(bad, "w", encoding="utf-8", newline="").write(orig)

        # 3. broken XML
        io.open(bad, "w", encoding="utf-8", newline="").write(orig[:-20])
        r = run(feed_code, tmp)
        expect("malformed RSS fails", r.returncode != 0)
        io.open(bad, "w", encoding="utf-8", newline="").write(orig)

        # 4. JSON Feed wrong version
        feed = os.path.join(tmp, "public", "feed.json")
        orig_feed = io.open(feed, encoding="utf-8").read()
        mutate_read(feed, '"version":"https://jsonfeed.org/version/1.1"', '"version":"https://jsonfeed.org/version/1.0"')
        r = run(feed_code, tmp)
        expect("wrong JSON Feed version fails", r.returncode != 0)
        io.open(feed, "w", encoding="utf-8", newline="").write(orig_feed)

        # 5. duplicate ids in JSON Feed
        import json
        data = json.loads(orig_feed)
        data["items"][1]["id"] = data["items"][0]["id"]
        io.open(feed, "w", encoding="utf-8", newline="").write(json.dumps(data))
        r = run(feed_code, tmp)
        expect("duplicate item ids fail", r.returncode != 0)
        io.open(feed, "w", encoding="utf-8", newline="").write(orig_feed)

        print("metadata block")
        r = run(meta_code, tmp)
        expect("clean public passes", r.returncode == 0, r.stdout.strip()[-80:])

        post = os.path.join(tmp, "public", "posts", "what-can-change", "index.html")
        if not os.path.exists(post):
            post = sorted(
                os.path.join(dp, f)
                for dp, _, fs in os.walk(os.path.join(tmp, "public"))
                for f in fs if f == "index.html" and "/posts/" in dp
            )[0]
        orig_post = io.open(post, encoding="utf-8").read()

        # 6. broken JSON-LD
        idx = orig_post.find('{"@context":"https://schema.org","@type":"BlogPosting"')
        assert idx != -1, "BlogPosting block not found"
        mutated = orig_post[:idx] + orig_post[idx:].replace("}", "", 1)
        io.open(post, "w", encoding="utf-8", newline="").write(mutated)
        r = run(meta_code, tmp)
        expect("broken JSON-LD fails", r.returncode != 0)
        io.open(post, "w", encoding="utf-8", newline="").write(orig_post)

        # 7. target=_blank without rel
        mutated = re.sub(r'<a [^>]*target=_blank[^>]*>',
                         lambda m: re.sub(r"\s*rel=['\"][^'\"]*['\"]", "", m.group(0)),
                         orig_post, count=1)
        io.open(post, "w", encoding="utf-8", newline="").write(mutated)
        r = run(meta_code, tmp)
        expect("target=_blank without rel fails", r.returncode != 0)
        io.open(post, "w", encoding="utf-8", newline="").write(orig_post)

        # 8. post-content external link loses sg-ext
        mutated = orig_post.replace("class=sg-ext", "", 1).replace('class="sg-ext"', "", 1)
        io.open(post, "w", encoding="utf-8", newline="").write(mutated)
        r = run(meta_code, tmp)
        expect("missing sg-ext fails", r.returncode != 0)
        io.open(post, "w", encoding="utf-8", newline="").write(orig_post)

        # 9. internal link wrongly tagged sg-ext: take a real sg-ext
        # anchor inside post content and point it back at the site host.
        # The host comes from the page canonical so this survives a baseURL
        # change (the harness must not hard-code the demo domain).
        canon = re.search(r'<link rel=canonical href=["\']?(https://[^/"\' >]+)', orig_post)
        assert canon, "no canonical link on the post page"
        site_origin = canon.group(1)
        hit = re.search(r'<a href=(https://[^/ >]+)([^ >]*) class=sg-ext>', orig_post)
        assert hit, "no sg-ext anchor to repoint"
        mutated = orig_post.replace(
            hit.group(0),
            "<a href=%s%s class=sg-ext>" % (site_origin, hit.group(2)),
            1,
        )
        io.open(post, "w", encoding="utf-8", newline="").write(mutated)
        r = run(meta_code, tmp)
        expect("internal link with sg-ext fails", r.returncode != 0)
        io.open(post, "w", encoding="utf-8", newline="").write(orig_post)

        # 10. non-schema.org @context
        mutated = orig_post.replace('"@context":"https://schema.org"', '"@context":"https://example.com"', 1)
        io.open(post, "w", encoding="utf-8", newline="").write(mutated)
        r = run(meta_code, tmp)
        expect("wrong @context fails", r.returncode != 0)
        io.open(post, "w", encoding="utf-8", newline="").write(orig_post)

        # 11. the post block loses its id — the anchor every selector relies on
        assert "id=ld-post" in orig_post, "post block has no id=ld-post to remove"
        mutated = orig_post.replace("id=ld-post", "", 1)
        io.open(post, "w", encoding="utf-8", newline="").write(mutated)
        r = run(meta_code, tmp)
        expect("missing JSON-LD id fails", r.returncode != 0)
        io.open(post, "w", encoding="utf-8", newline="").write(orig_post)

        # 12. the homepage block is still an Organization but under another id
        home = os.path.join(tmp, "public", "index.html")
        orig_home = io.open(home, encoding="utf-8").read()
        assert "id=ld-org" in orig_home, "homepage block has no id=ld-org to rename"
        io.open(home, "w", encoding="utf-8", newline="").write(orig_home.replace("id=ld-org", "id=ld-home", 1))
        r = run(meta_code, tmp)
        expect("wrong homepage JSON-LD id fails", r.returncode != 0)
        io.open(home, "w", encoding="utf-8", newline="").write(orig_home)

        # 13. wordCount demoted back to a string
        mutated, hits = re.subn(r'"wordCount":(\d+)', r'"wordCount":"\1"', orig_post, count=1)
        assert hits == 1, "post block has no numeric wordCount to quote"
        io.open(post, "w", encoding="utf-8", newline="").write(mutated)
        r = run(meta_code, tmp)
        expect("quoted wordCount fails", r.returncode != 0)
        io.open(post, "w", encoding="utf-8", newline="").write(orig_post)

        print("llms-full block")
        r = run(llms_code, tmp)
        expect("clean public passes", r.returncode == 0, r.stdout.strip()[-80:])

        full = os.path.join(tmp, "public", "llms-full.txt")
        index = os.path.join(tmp, "public", "llms.txt")
        orig_full = io.open(full, encoding="utf-8").read()
        orig_index = io.open(index, encoding="utf-8").read()

        # 14. llms-full.txt removed entirely
        os.remove(full)
        r = run(llms_code, tmp)
        expect("missing llms-full.txt fails", r.returncode != 0)
        io.open(full, "w", encoding="utf-8", newline="").write(orig_full)

        # 15. a post section is missing from the full text
        headings = re.findall(r"^## (.+)$", orig_full, re.M)
        assert headings, "llms-full.txt has no post sections"
        victim = [h for h in headings if not h.startswith("Pages")][0]
        mutated = orig_full.replace("## " + victim, "## " + victim + " (renamed)", 1)
        io.open(full, "w", encoding="utf-8", newline="").write(mutated)
        r = run(llms_code, tmp)
        expect("missing per-post section fails", r.returncode != 0)
        io.open(full, "w", encoding="utf-8", newline="").write(orig_full)

        # 16. llms.txt stops advertising the full text
        mutated = re.sub(r"^- \[llms-full\.txt\].*\n", "", orig_index, count=1, flags=re.M)
        assert mutated != orig_index, "llms.txt has no llms-full link to remove"
        io.open(index, "w", encoding="utf-8", newline="").write(mutated)
        r = run(llms_code, tmp)
        expect("llms.txt without the llms-full link fails", r.returncode != 0)
        io.open(index, "w", encoding="utf-8", newline="").write(orig_index)

        # 17. an HTML entity survives into the plain-text body
        mutated = orig_full.replace("\n\n", "\n\n&#34;quoted&#34; ", 1)
        assert mutated != orig_full, "llms-full.txt has no blank line to seed"
        io.open(full, "w", encoding="utf-8", newline="").write(mutated)
        r = run(llms_code, tmp)
        expect("HTML entity in llms-full fails", r.returncode != 0)
        io.open(full, "w", encoding="utf-8", newline="").write(orig_full)

        print("assets block")
        r = run(assets_code, tmp)
        expect("clean public passes", r.returncode == 0, r.stdout.strip()[-80:])

        # 18. a stray console.log reaches the shipped bundle
        bundle = sorted(glob_mod.glob(os.path.join(tmp, "public", "assets", "js", "*.js")))[0]
        orig_bundle = io.open(bundle, encoding="utf-8").read()
        io.open(bundle, "w", encoding="utf-8", newline="").write(orig_bundle + "\nconsole.log(x);\n")
        r = run(assets_code, tmp)
        expect("console.log in a bundle fails", r.returncode != 0)
        io.open(bundle, "w", encoding="utf-8", newline="").write(orig_bundle)

    print()
    if failures:
        print("NEGATIVE TESTS FAILED: " + ", ".join(failures))
        return 1
    print("all negative tests pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
