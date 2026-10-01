# hugo-theme-sigil

**[English](README.md)** | [中文](README.zh.md) | 日本語

[Hugo](https://gohugo.io/) 向けの控えめな文学系テーマです。
[PaperMod](https://github.com/adityatelange/hugo-PaperMod) をベースにしています。

デモ：<https://ouatis.com/hugo-theme-sigil/>

## 特徴

- ワイド画面の Tufte 風サイドノートと狭い画面の脚注
- Ghost-year 年別アーカイブ
- 円形リビール式ダークモード
- 全文 RSS
- IBM Plex と CJK フォントサブセット
- JSON Feed 1.1(`/feed.json`、RSS と並存、ビルド時に自動生成)
- 検索、分類、タグ、パンくず、目次、コードコピー、多言語文字列
- ページ単位で有効化:KaTeX 数式(同梱)、Mermaid 図(固定版 CDN)、画像ライトボックス(glightbox、同梱)
- 記事タイトルから OG 画像カードを自動生成(`images.Text`、ビルド時のみ)
- 外部リンクの扉マークはレンダーフックがホスト名で判定(ドメイン直書きなし)

## インストール

git サブモジュールとして：

```bash
git submodule add https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
```

```toml
# hugo.toml
theme = "hugo-theme-sigil"
```

または [Hugo モジュール](https://gohugo.io/hugo-modules/) として：

```bash
hugo mod init github.com/you/your-site   # サイトに既に go.mod があれば不要
```

```toml
# hugo.toml
[module]
  [[module.imports]]
    path = "github.com/ouatis/hugo-theme-sigil"
```

サンプルサイトのプレビュー：

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

## 設定

PaperMod の一般的な設定を利用できます。Sigil 固有の設定：

| パラメータ | 初期値 | 用途 |
| --- | --- | --- |
| `sgKicker` | 非表示 | ホームタイトル上のテキスト |
| `sgHomeTitle` | サイトタイトル | ホームタイトル |
| `sgReading` / `sgPlaying` / `sgMotto` | 非表示 | ホームのステータス |
| `sgSealImage` | `∴` | ホームの印章画像 |
| `sgDaysInCage` | `false` | ステータス行の経過日数「Day N in the Cage」,最古の投稿から起算 |
| `ShowFullTextinRSS` | `false` | RSS に全文を含める |
| `ShowAllPagesInArchive` | `false` | アーカイブに全ページを含める |
| `homePageSize` | すべて | 1ページの投稿数 |
| `sgSeriesFrom` | 非表示 | シリーズナビ:策展ページの本文リストを読み順に;`sgSeriesTab` でタブラベル |
| `math` / `mermaid` / `lightbox` | `false` | ページの frontmatter かサイト全体で有効化:KaTeX 数式、Mermaid 図、画像ライトボックス。要求しないページは何も読まない。`$$…$$` はそのまま動作 — 行内 `\(…\)` は goldmark passthrough も有効化([exampleSite/hugo.toml](exampleSite/hugo.toml) 参照) |
| `ogAutoCard` | `false` | カバー画像のないページに、タイトル+サイト名で 1200×630 の OG カードをビルド時に生成 |
| `ogCardFont` | 同梱 Plex Serif | OG カード用 TTF の `resources.Get` パス。同梱はラテン文字のみ — CJK サイトはタイトル用字のサブセット TTF を用意して指定 |
| `analytics.*` | 非表示 | サードパーティ統計(本番のみ):`analytics.plausible.domain`、`analytics.umami`(`src` + `id`)、`analytics.goatcounter.code`、`analytics.fathom.site` |

完全な例は [exampleSite/hugo.toml](exampleSite/hugo.toml) を参照してください。

## フォント

ラテン文字用 IBM Plex は同梱されています。CJK サブセットを再生成するには：

```bash
bash scripts/build-fonts.sh
# または
python scripts/build-fonts.py
```

## ライセンス

MIT。詳細は [LICENSE](LICENSE) を参照してください。

PaperMod ベース。フォントは IBM Plex（SIL OFL 1.1）、アイコンは Phosphor
Icons（MIT）、検索は Fuse.js（Apache-2.0）、数式は KaTeX（MIT、同梱）、
ライトボックスは glightbox（MIT、同梱）、図は Mermaid（MIT、必要なページのみ固定版 CDN）。
