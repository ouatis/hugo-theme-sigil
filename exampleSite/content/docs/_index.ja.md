---
title: "ドキュメント"
translationKey: "docs"
slug: docs
---

# ドキュメント

SIGIL を自分のものにするために必要なすべて。このページは地図です。
[設定例](../../config-example/) はそのまま使える出発点、
[API 契約](../../api/) は凍結された正式リファレンス。要件とインストールは
[README](https://github.com/ouatis/hugo-theme-sigil#install) に。

{{< page-anatomy >}}

## はじめに

SIGIL は Hugo ≥ 0.166 extended で動作し、ビルド手順は不要です。`baseURL` を設定し、
設定例から `[params]` を選び、Markdown で記事を書きます。標準でラテン組版、傍注、
検索、ダークモードが使えます。日本語を実際の Plex で出したい場合は、任意のフォント
サブセット（`bash scripts/build-fonts.sh corpus`）が必要です。入れなければシステム
フォントにフォールバックします。

## 機能の使いかた

各機能はページ単位で opt-in です。ページが要求しないものは読み込まれません。記事の
front matter で：

```toml
math    = true   # KaTeX。$...$ と \(...\) に対応
mermaid = true   # ```mermaid ブロックからの図
lightbox = true  # 画像のクリック拡大
```

- **傍注** —— 脚注 `[^1]` を書き、末尾で `[^1]: 注の内容` と定義します。広い画面では
  余白に浮かび、狭い画面では巻末の注に畳まれます。テーマ固有の構文ではなく、普通の
  Markdown です。
- **多言語** —— 各言語の翻訳に同じ `translationKey` を付けると、言語切替が対応する記事へ
  飛びます。翻訳のないページはその言語のホームに戻ります。右から左に書く言語
  （アラビア語・ペルシャ語・ヘブライ語・中央クルド語）は、サイト設定で
  `direction = "rtl"` を指定すれば、傍注・浮遊目次・矢印を含むレイアウト全体が
  鏡像になります。
- **フォント** —— `latin`（既定・クリーンな状態）、`corpus`（デモの日本語、約 200 KB）、
  `full`（SC + JP 全体、約 3 MB）。ページではなくサイト単位で選びます。

[組版の見本](../posts/typography/) に、これらすべてが一ページにまとまっています——
自分で書く前に、結果を確かめてください。

## 設定

[設定例](../../config-example/) がコピー＆ペースト用の出発点です。[API 契約](../../api/) が完全な
リファレンスです。まずはよく使う選択肢を以下にまとめます。

### 目的から設定を探す

| やりたいこと | 設定 | 適用範囲 |
| --- | --- | --- |
| ホームタイトルの上に一行を表示する | `sgKicker` | サイト |
| ホームタイトルまたは印章を変える | `sgHomeTitle` / `sgSealImage` | サイト |
| ステータス行を切り替える | `sgReading` / `sgListening` / `sgWatching` / `sgPlaying` / `sgWriting` / `sgExploring` / `sgMotto` の任意 | サイト |
| ホーム件数を制限またはシリーズパネルを付ける | `homePageSize` / `sgSeriesFrom` | サイト |
| RSS に全文を含める | `ShowFullTextinRSS` | サイト |
| エージェント向けの索引を出す | `[outputs] home` に `LLMSTXT`、必要なら `LLMSFULL` | サイト |
| 表紙のないページに OG カードを作る | `ogAutoCard`（CJK は `ogCardFont` も） | サイト |
| 数式・図・ライトボックスを有効にする | `math` / `mermaid` / `lightbox` | ページ／サイト |
| ページをホームまたは検索から外す | `hiddenInHomeList` / `searchHidden` | ページ |
| 関連記事またはコメントを消す | `showRelated: false` / `comments: false` | ページ |

### 必須のサイト設定

PaperMod の一般的な設定はそのまま使えます。SIGIL の最小設定です。不要なホーム項目は削除できます。

```toml
[params]
  mainSections = ["posts"]
  sgKicker = "Notes from the Margins"
  sgHomeTitle = "SIGIL"
  sgSealImage = "/images/seal.png"
  homePageSize = 10

  # 任意の組み合わせ。6 秒ごとに切り替え、prefers-reduced-motion を尊重
  sgReading = "The Book of Disquiet"
  sgPlaying = "Disco Elysium"
  sgMotto = "Ink, paper, and everything in threes."

# 検索には JSON 出力形式と検索ページが必要
[outputs]
  home = ["HTML", "RSS", "JSON", "JSONFeed", "LLMSTXT", "LLMSFULL"]

[params.fuseOpts]
  isCaseSensitive = false
  shouldSort = true
  minMatchCharLength = 2
  keys = ["title", "summary", "content"]

# Tufte サイドノートには Markdown 内の生 HTML が必要
[markup.goldmark.renderer]
  unsafe = true
```

### 機械可読出力

`LLMSTXT` でページと記事の索引を、`LLMSFULL` で同じヘッダーに続く全記事の本文を出力します。
クライアントサイド検索を有効にする場合は、出力リストに `JSON` も残してください。キーページ節は
About、アーカイブ、タクソノミー、RSS を自動検出します。手で編集する場合は
`layouts/home.llmstxt.txt` を上書きしてください。

front matter のスイッチは `hiddenInHomeList`、`searchHidden`、`showRelated: false`、
`comments: false` です。PaperMod から継承する項目と SIGIL の全機能は [API 契約](../../api/) を参照してください。

## フォントと性能

テーマはラテン文字のサブセットを同梱しており、フォントのビルドなしで使えます。デモの CJK を IBM Plex
で表示するには `bash scripts/build-fonts.sh corpus` を実行してください。現在の SC レギュラー＋ボールドの
コーパスは約 200 KB です。`full` は SC + JP 全体を含み、文字の多いページで約 3 MB です。

デモの minify ビルドは HTML と CSS の合計が 100 KB 未満で、実行時の外部 JavaScript はありません。
オプションのリソースは要求時だけ読み込みます：検索は約 18 KB、KaTeX はフォント込みで約 300 KB、
GLightbox は約 70 KB です。文字の多いページのフォントは英語／中国語で約 284 KB、日本語で約 222 KB、
CI の予算は 320 KB です。

## API リファレンス

テーマの公開契約は v0.12.0 で凍結されています。記載されたパラメータは、非推奨期間を経ずに
改名・削除されることはありません。[API 契約](../../api/) に、すべてのサイトパラメータ、front matter
パラメータ、CSS フック、拡張ポイントが記載されています。そこに記載のないものは内部実装で、
告知なく変更されえます。

> 詳細な技術ドキュメントは現在英語版のみです。上記の `/config-example/`、`/api/` のリンクは英語原文を参照します。
