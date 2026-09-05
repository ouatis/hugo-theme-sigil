# hugo-theme-sigil

[English](README.md) | [中文](README.zh.md) | **日本語**

シンプルな Hugo ブログテーマ：古紙の背景、朱・墨緑・琥珀の三色体系、IBM Plex Sans CJK の
組み版、Tufte 式の傍注、全文 RSS、サイト内の使用文字だけを切り出すフォントサブセット
pipeline。[PaperMod](https://github.com/adityatelange/hugo-PaperMod)（MIT）を深くカスタム。

**[デモ](https://ouatis.com/hugo-theme-sigil/)**

![Screenshot](docs/screenshot.png)

## クイックスタート

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

自分のサイトで使う：

```bash
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# hugo.toml: theme = "hugo-theme-sigil"
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

傍注・アーカイブの背景年数・円形揭示のテーマ切り替えは自動動作で、設定不要。完全な例は
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

## ライセンス

MIT — [LICENSE](LICENSE) を参照。ベース：[PaperMod](https://github.com/adityatelange/hugo-PaperMod)。フォント：[IBM Plex](https://github.com/IBM/plex)（IBM オープンソースフォントライセンス）。アイコン：[Phosphor Icons](https://phosphoricons.com/)（MIT）。
