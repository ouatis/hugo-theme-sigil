#!/usr/bin/env python3
"""Negative tests for the two new check.sh contract blocks.

Extracts each heredoc block from scripts/check.sh, runs it against a pristine
copy of exampleSite/public (must pass), then against mutated copies (must fail).
"""
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
    for lineno, code in blocks():
        if "JSON Feed" in code and "pubDate" in code:
            feed_code = code
        if "ld+json" in code and "noopener" in code:
            meta_code = code
    assert feed_code and meta_code, "could not locate both blocks"

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

    print()
    if failures:
        print("NEGATIVE TESTS FAILED: " + ", ".join(failures))
        return 1
    print("all negative tests pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
