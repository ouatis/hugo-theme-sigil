# hugo-theme-sigil

[中文](README.md) | [English](README.en.md) | **日本語**

シンプルな Hugo ブログテーマ：古紙の背景、朱・墨緑・琥珀の三色体系、IBM Plex Sans CJK の
組み版、Tufte 式の傍注、全文 RSS、サイト内の使用文字だけを切り出すフォントサブセット
pipeline。[PaperMod](https://github.com/adityatelange/hugo-PaperMod)（MIT）を深くカスタム。

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

| パラメータ | 説明 | デフォルト |
| --- | --- | --- |
| `params.sgKicker` | トップページのタイトル上部の小さな行 | 非表示 |
| `params.sgReading` / `params.sgPlaying` / `params.sgMotto` | Hero の印章下の輪換ステータス | 非表示 |
| `params.sgSealImage` | トップページの印章画像。未設定なら ∴ の文字印章 | ∴ 文字印章 |
| `params.mainSections` | トップページ一覧と RSS の対象セクション | `["posts"]` |
| `params.author` | 記事の署名（RSS と記事 meta） | 非表示 |

完全な例は [exampleSite/hugo.toml](exampleSite/hugo.toml) を参照。サンプルサイトは中国語のみです。テーマには zh-CN / en / ja の文案が同梱されています。

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

MIT — [LICENSE](LICENSE) を参照。ベース：[PaperMod](https://github.com/adityatelange/hugo-PaperMod)。フォント：[IBM Plex](https://github.com/IBM/plex)（IBM オープンソースフォントライセンス）。
