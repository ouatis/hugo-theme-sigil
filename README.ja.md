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
- 検索、分類、タグ、パンくず、目次、コードコピー、多言語文字列

## インストール

```bash
git submodule add https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
```

```toml
# hugo.toml
theme = "hugo-theme-sigil"
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
| `ShowFullTextinRSS` | `false` | RSS に全文を含める |
| `ShowAllPagesInArchive` | `false` | アーカイブに全ページを含める |
| `homePageSize` | すべて | 1ページの投稿数 |

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
Icons（MIT）、検索は Fuse.js（Apache-2.0）です。
