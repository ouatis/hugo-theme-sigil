---
title: "Documentation"
translationKey: "docs"
slug: docs
categories: []
---

# Documentation

Everything you need to make Sigil your own.

## Getting Started

Sigil runs on Hugo 0.166 extended with no build step. The
[README](https://github.com/ouatis/hugo-theme-sigil#installation) covers
requirements and installation; the
[configuration examples]({{% relref "config-example.md" %}}) are copy-paste
starting points for `hugo.toml`.

## Features

The best way to understand Sigil is to read it.
[Typography]({{% relref "posts/typography/_index.md" %}}) demonstrates
sidenotes, math, diagrams, and code; the
[archives]({{% relref "archives.md" %}}) show how posts are indexed. Each
feature is opt-in via front matter, so nothing loads unless a page asks for it.

## API Reference

The theme's public contract is frozen as of v0.9.0 — listed parameters will not
be renamed or removed without a deprecation window. The
[API contract]({{% relref "api.md" %}}) is the reference; treat anything not
listed there as internal.
