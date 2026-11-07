---
title: "文档"
translationKey: "docs"
slug: docs
---

# 文档

让 SIGIL 成为你自己的主题所需的一切。这一页是地图；
[配置示例](../../config-example/) 是可复制的起点，
[API 契约](../../api/) 是冻结的权威参考。环境要求与安装见
[README](https://github.com/ouatis/hugo-theme-sigil#install)。

{{< page-anatomy >}}

## 开始使用

SIGIL 基于 Hugo ≥ 0.166 extended，无需构建步骤。设好 `baseURL`，从示例里挑一段
`[params]`，用 Markdown 写文章即可。开箱即有拉丁排版、旁注、搜索和深色模式；
中文需要可选的字体子集（`bash scripts/build-fonts.sh corpus`）才会用真正的 Plex
渲染，否则回退到系统字体。

## 用上这些功能

每项功能按页面 opt-in，页面不声明就不会加载。在文章的 front matter 里：

```toml
math    = true   # KaTeX，支持 $...$ 与 \(...\)
mermaid = true   # Mermaid 图，来自 ```mermaid 代码块
lightbox = true  # 图片点击放大
```

- **旁注** —— 写脚注 `[^1]` 并在文末定义 `[^1]: 注释内容`。宽屏上它浮到页边，
  窄屏上收进文末尾注。就是普通 Markdown，没有主题专有语法。
- **多语言** —— 给各语言翻译相同的 `translationKey`，语言切换器会跳到对应文章；
  没有翻译的页面回退到该语言首页。右到左语言（阿拉伯语、波斯语、希伯来语、中库尔德语）
  在站点配置里声明 `direction = "rtl"` 后，边注、悬浮目录与箭头会整体镜像。
- **字体** —— `latin`（默认，干净检出）、`corpus`（演示站中文，约 200 KB）、
  `full`（完整 SC + JP，约 3 MB）。按站点选，不按页面。

[排版示例](../posts/typography/) 把这些功能集中在一页——写自己的文章之前，先读它看看效果。

## 配置

[配置示例](../../config-example/) 是复制粘贴的起点。[API 契约](../../api/) 是完整参考；
下面先列最常用的选择。

### 按目的查配置

| 我想…… | 设置 | 作用范围 |
| --- | --- | --- |
| 在首页标题上方加一行小字 | `sgKicker` | 站点 |
| 修改首页标题或印章 | `sgHomeTitle` / `sgSealImage` | 站点 |
| 轮播状态条 | `sgReading` / `sgListening` / `sgWatching` / `sgPlaying` / `sgWriting` / `sgExploring` / `sgMotto` 任一 | 站点 |
| 限制首页篇数或增加系列浮窗 | `homePageSize` / `sgSeriesFrom` | 站点 |
| 在 RSS 中发布全文 | `ShowFullTextinRSS` | 站点 |
| 给 Agent 输出索引 | `[outputs] home` 中加入 `LLMSTXT`，可选 `LLMSFULL` | 站点 |
| 为无封面的页面生成 OG 卡片 | `ogAutoCard`（中文站另配 `ogCardFont`） | 站点 |
| 加数学公式、图表或灯箱 | `math` / `mermaid` / `lightbox` | 单页或站点 |
| 让页面不进首页或搜索 | `hiddenInHomeList` / `searchHidden` | 单页 |
| 关闭相关阅读或评论 | `showRelated: false` / `comments: false` | 单页 |

### 必备站点配置块

PaperMod 的常用配置可以继续使用。下面是最小的 SIGIL 配置；不用的首页行可以删掉：

```toml
[params]
  mainSections = ["posts"]
  sgKicker = "A Hugo theme"
  sgHomeTitle = "SIGIL"
  sgSealImage = "/images/seal.png"
  homePageSize = 10

  # 任意子集；每 6 秒轮换并尊重 prefers-reduced-motion
  sgReading = "The Book of Disquiet"
  sgPlaying = "Disco Elysium"
  sgMotto = "Ink, paper, and everything in threes."

# 搜索需要 JSON 输出格式和搜索页
[outputs]
  home = ["HTML", "RSS", "JSON", "JSONFeed", "LLMSTXT", "LLMSFULL"]

[params.fuseOpts]
  isCaseSensitive = false
  shouldSort = true
  minMatchCharLength = 2
  keys = ["title", "summary", "content"]

# Tufte 旁注需要 Markdown 中的原始 HTML
[markup.goldmark.renderer]
  unsafe = true
```

### 机器可读输出

加入 `LLMSTXT` 可生成页面与文章索引，加入 `LLMSFULL` 则在相同头部后附上每篇文章全文。
启用客户端搜索时，输出列表中也要保留 `JSON`。关键页面一节会自动发现关于、归档、词目
和 RSS；需要手工策展时覆盖 `layouts/home.llmstxt.txt`。

front matter 开关包括 `hiddenInHomeList`、`searchHidden`、`showRelated: false` 和
`comments: false`。继承自 PaperMod 的选项与完整 SIGIL 表面见 [API 契约](../../api/)。

## 字体与性能

主题内置拉丁子集，无需构建字体即可使用。若要让演示站的中文使用 IBM Plex，运行
`bash scripts/build-fonts.sh corpus`；当前 SC 常规与粗体语料约 200 KB。`full` 提供完整 SC + JP
覆盖，文字密集页约 3 MB。

演示站 minify 构建的 HTML 加 CSS 不到 100 KB，运行时不加载外部 JavaScript。可选资源只在请求时加载：
搜索约 18 KB，KaTeX 约 300 KB 加字体，GLightbox 约 70 KB，图表引擎约 275 KB（gzip）。文字密集页的字体约为中文 284 KB、日文
222 KB，CI 预算上限为 320 KB。

## API 参考

主题的公共契约自 v0.12.0 起冻结——列出的参数不会在没有弃用期的情况下改名或移除。
[API 契约](../../api/) 列出了每个站点参数、front matter 参数、CSS 钩子和扩展点。
其中未列出的内容均属内部实现，可随时更改而不另行通知。

> 详细技术文档目前仅有英文版；上述 `/config-example/`、`/api/` 链接指向英文原文。

## 食谱

在主题之上常见搭建——每条都用今天就在的机制，无需另装：

- **覆写一个 partial。** 在站点建 `layouts/partials/extend_post_content.html`，
  它渲染的内容出现在每篇文章正文之后——跋、系列导语、许可行皆可。
  `extend_head.html` 与 `extend_footer.html` 同理。
- **站点级样式。** 站点 `assets/css/extended/*.css` 里的任何规则都后于主题
  加载，同权重必胜——改细线、静化界面、调纸色，无需分叉主题。
- **CI 里做字体。** 调用 reusable workflow
  （`ouatis/hugo-theme-sigil/.github/workflows/fonts.yml`，`mode` 入参），
  字体子集以 artifact 形式送达你的 `static/fonts`。
- **一个系列。** 把 `sgSeriesFrom` 指向一页目录稿，正文清单即阅读顺序；
  浮动面板随之出现在每篇成员文章上。
- **CJK OG 卡。** 把 `ogCardFont` 指向能画出你标题的子集 TTF，开 `ogAutoCard`——
  每个无封面的页面都会带一张纸卡。
- **页面级自选。** `math`、`mermaid`、`lightbox`、`showRelated`、
  `hiddenInHomeList`——每页只加载它自己点名的。
