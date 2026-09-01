# hugo-theme-sigil

[中文](README.md) | [English](README.en.md) | **日本語**

**A literary Hugo theme — ink, paper, and everything in threes.**
（文学のための Hugo テーマ — インク、紙、そしてすべては三つでできている。）

> [!IMPORTANT]
> **このテーマは主に中国語の書き手のために作られています。** フォントの
> サブセット pipeline、組み版の設定、欄幅と行間は、すべて中国語の読書体験を
> 中心に設計されています。他の言語でも利用できますが、設計と最適化は中国語の読書体験を優先しています。
> （中文说明见 [README.md](README.md)；For English, see [README.en.md](README.en.md)。）

[PaperMod](https://github.com/adityatelange/hugo-PaperMod)（MIT）を深くカスタム
した文学系 Hugo テーマ：古紙の背景、朱・墨緑・琥珀の三色体系、明朝体の組み版、
Tufte 式の傍注、全文 RSS、そしてサイト内の使用文字だけを切り出すフォント
サブセット pipeline。

![Screenshot](docs/screenshot.png)

## 特徴

- **三色体系** — 朱（インタラクション）・墨緑（メタ情報）・琥珀（ハイライト）、ダーク＆ライト両対応
- **Tufte 式傍注** — 広い画面では注釈が参照箇所の右側の余白に表示され、狭い画面では文末に自動フォールバック
- **フォントサブセット pipeline** — `scripts/build-fonts.sh` がサイト内の使用文字から源ノ宋体をスライスし、初回訪問は数 KB のダウンロードで済む
- **全文 RSS**
- **タイプしながら検索**（fuse）
- **アーカイブ / 分類 / タグ / パンくず / 読書進捗**
- **多言語** — zh-CN / en / ja の文案を内蔵
- 紙の目、三段式のコロフォン、ホバーで呼応する印章など、静かなディテール

## クイックスタート

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

自分のサイトで使う：

```bash
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# hugo.toml:
# theme = "hugo-theme-sigil"
```

## 設定

| パラメータ | 説明 | デフォルト |
| --- | --- | --- |
| `params.sgKicker` | トップページのタイトル上部の小さな行 | 非表示 |
| `params.sgColophon` | 三段フッターの中央に入る標語 | 非表示 |
| `params.sgSealImage` | トップページの印章画像。未設定なら ∷ ではなく ∴ の文字印章 | ∴ 文字印章 |
| `params.mainSections` | トップページ一覧と RSS の対象セクション | `["posts"]` |
| `params.author` | 記事の署名（RSS と記事 meta で使用） | 非表示 |

完全な例は [exampleSite/hugo.toml](exampleSite/hugo.toml) を参照。

## フォントサブセット

本文のセリフ体は源ノ宋体（Noto Serif SC、SIL OFL 1.1）。初回ビルド前に実行：

```bash
pip install "fonttools[woff]"
scripts/build-fonts.sh
```

スクリプトはサイト内の使用文字をすべて走査し、unicode-range ごとの woff2 スライスを
生成します。読者は 20MB のフォント一式ではなく、必要な数 KB だけをダウンロード。
実行しない場合はシステムの明朝体にフォールバックします。

## 傍注 / Sidenotes

脚注は広い画面（≥1440px、Tufte 式）では参照箇所の右側の余白に表示されます。
参照にホバーすると対応する傍注がハイライト（逆方向も）。狭い画面では文末脚注に、
印刷では文末リストにフォールバック。`:has` 非対応のブラウザでは通常の脚注のまま。

## クレジット

ベース：[PaperMod](https://github.com/adityatelange/hugo-PaperMod)（MIT）。
フォント：[源ノ宋体](https://fonts.google.com/noto/specimen/Noto+Serif+SC)（SIL OFL 1.1）。

## ライセンス

MIT — [LICENSE](LICENSE) を参照。
