# hugo-theme-sigil

[English](README.md) | [中文](README.zh.md) | **日本語**

**[Hugo](https://gohugo.io/) 用のミニマルな文学テーマ：古紙の地に、三色の墨、
内容の引き立て役に徹する組み版。**

[![Hugo Themes](https://img.shields.io/badge/Hugo--Themes-@sigil-blue)](https://themes.gohugo.io/themes/hugo-theme-sigil/)
[![Minimum Hugo Version](https://img.shields.io/static/v1?label=Hugo&message=v0.156.0%2B&color=blue&logo=hugo)](https://github.com/gohugoio/hugo/releases)
[![Release](https://img.shields.io/github/v/tag/ouatis/hugo-theme-sigil?sort=semver&label=release)](https://github.com/ouatis/hugo-theme-sigil/releases)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> [PaperMod](https://github.com/adityatelange/hugo-PaperMod) を深くカスタムしたものです。
> 独立テーマとしている理由は[下記の説明](#papermod-との違い)を参照。

|  |  |
| --- | --- |
| **デモ** | <https://ouatis.com/hugo-theme-sigil/> |
| **組版ショーケース** | <https://ouatis.com/hugo-theme-sigil/posts/typography/> |
| **サンプルサイトのソース** | [exampleSite/](exampleSite/) |

![Screenshot](https://raw.githubusercontent.com/ouatis/hugo-theme-sigil/main/images/screenshot.png)

---

## 特徴

`∴ 朱は応える · 墨緑は伝える · 琥珀は灯す`

- **Tufte 式の傍注** -- 広い画面（≥1280px）では脚注が参照箇所の右側の余白に組み込まれ、狭い画面では文末にフォールバック。
- **円形揭示のテーマ切り替え** -- ダークモードがクリック位置から円形に展開（View Transitions API）。未対応環境ではソフトなトランジションにフォールバック。
- **ゴースト年号のアーカイブ** -- アーカイブページの年号は背景の大きな数字。
- **全文 RSS** -- フィードで要約ではなく本文を読める。
- **CJK フォントサブセット** -- `build-fonts.sh` が unicode-range ごとの IBM Plex woff2 スライスを生成。読者のダウンロードは数 KB。
- **三色の体系** -- 朱、墨緑、琥珀。第四の色はない。
- **PaperMod の基本機能** -- Fuse.js 検索、タクソノミー、パンくずリスト、目次、コードコピーボタン、OG / Twitter / Schema メタデータ、zh-CN / en / ja の同梱文案。

## インストール

まずサンプルサイトで試す：

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

自分のサイトで使う：

```bash
# git サブモジュールとして（CI デプロイに推奨）
git submodule add https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# または素のクローン
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
```

```toml
# hugo.toml
theme = "hugo-theme-sigil"
```

デプロイ前に `baseURL` を自分のドメインに変更してください（サンプルサイトは `https://example.com/` のまま入っています）。

## 設定

テーマ固有のパラメータ：

| パラメータ | デフォルト | 説明 |
| --- | --- | --- |
| `sgKicker` | 非表示 | トップページのタイトル上部の小さな行 |
| `sgReading` / `sgPlaying` / `sgMotto` | 非表示 | Hero の印章下の輪換ステータス |
| `sgSealImage` | ∴ 文字印章 | トップページの印章画像 |
| `ShowFullTextinRSS` | `false` | RSS に全文を出力 |
| `ShowAllPagesInArchive` | `false` | アーカイブに投稿以外のページも収録 |
| `disableLangToggle` | `false` | 言語切り替えを隠す |
| `disableSpecial1stPost` | `false` | トップページの最初のエントリを通常スタイルに |

PaperMod から継承した常用パラメータはそのまま使えます：

| パラメータ | デフォルト | 説明 |
| --- | --- | --- |
| `defaultTheme` | `auto` | `light` / `dark` / `auto` |
| `ShowToc` / `TocOpen` | `false` | 記事の目次 |
| `ShowCodeCopyButtons` | `false` | コードブロックのコピーボタン |
| `ShowBreadCrumbs` | `false` | 記事のパンくずリスト |
| `ShowReadingTime` / `ShowWordCount` | `false` | 記事 meta |
| `ShowPostNavLinks` | `false` | 前 / 次の記事リンク |
| `showRelated` | `true` | 記事下の関連記事 |
| `editPost` | 非表示 | 記事下の「編集」リンク（`URL`、`Text`） |
| `socialIcons` | 非表示 | ソーシャルアイコン。github / rss / steam は Phosphor、それ以外は内蔵アイコンセットにフォールバック |
| `homeInfoParams` / `profileMode` | — | トップページのモードと内容 |
| `hideFooter`、`hideMeta`、`hideSummary` など | `false` | ページ単位の上書き |

傍注・アーカイブの背景年号・円形揭示のテーマ切り替えは自動動作で、設定不要。完全な例は
[exampleSite/hugo.toml](exampleSite/hugo.toml) を参照。サンプルサイトは英語です。テーマには zh-CN / en / ja の文案が同梱されています。

## フォントと傍注

初回ビルド前に実行：

```bash
pip install "fonttools[woff]"
scripts/build-fonts.sh
```

スクリプトはサイト内の使用文字から unicode-range ごとの woff2 スライスを生成し、
読者は必要な数 KB だけをダウンロードします。実行しない場合はシステムフォントに
フォールバックします。脚注は広い画面（≥1280px、Tufte 式）では参照箇所の右側の余白に表示され、
狭い画面では文末にフォールバックします。

## パフォーマンス

デモサイトの実測：アクセシビリティ 100 · ベストプラクティス 96 · CLS 0
（[Lighthouse](https://developer.chrome.com/docs/lighthouse/)、モバイル）。
[PageSpeed Insights](https://pagespeed.web.dev/report?url=https%3A%2F%2Fouatis.com%2Fhugo-theme-sigil%2F)
で再測定できます。

## PaperMod との違い

Sigil は PaperMod を深くカスタムしたものですが、以下の違いは上流に還元しづらいため、独立テーマとしています：

- **Tufte 式の傍注**：広い画面では脚注を参照箇所横の余白へ組み込み、狭い画面では文末へフォールバック。
- **円形揭示のテーマ切り替え**：View Transitions API でダークモードがクリック位置から円形に展開、ソフトなフォールバック付き。
- **ゴースト年号のアーカイブ**：年号を見出し行ではなく背景の大きな数字として組む。
- **全文 RSS とフォントサブセット pipeline**：`build-fonts.sh` が unicode-range ごとの IBM Plex スライスを生成し、CJK の読者のダウンロードを KB 単位に抑える。
- 厳格な三色の文学デザイン体系（朱 / 墨緑 / 琥珀）と zh-CN 優先の多言語文案。

## ライセンス

MIT — [LICENSE](LICENSE) を参照。

ベース：[PaperMod](https://github.com/adityatelange/hugo-PaperMod) · フォント：
[IBM Plex](https://github.com/IBM/plex)（SIL OFL 1.1）· アイコン：
[Phosphor Icons](https://phosphoricons.com/)（MIT）· 検索：
[Fuse.js](https://github.com/krisk/fuse)（Apache-2.0）
