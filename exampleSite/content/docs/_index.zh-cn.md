---
title: "文档"
translationKey: "docs"
slug: docs
---

# 文档

让 Sigil 成为你自己的主题所需的一切。这一页是地图；
[配置示例](/config-example/) 是可复制的起点，
[API 契约](/api/) 是冻结的权威参考。环境要求与安装见
[README](https://github.com/ouatis/hugo-theme-sigil#installation)。

## 开始使用

Sigil 基于 Hugo ≥ 0.166 extended，无需构建步骤。设好 `baseURL`，从示例里挑一段
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
  没有翻译的页面回退到该语言首页。
- **字体** —— `latin`（默认，干净检出）、`corpus`（演示站中文，约 30 KB）、
  `full`（完整 SC + JP，约 3 MB）。按站点选，不按页面。

[排版示例](/posts/typography/) 把这些功能集中在一页——写自己的文章之前，先读它看看效果。

## API 参考

主题的公共契约自 v0.9.0 起冻结——列出的参数不会在没有弃用期的情况下改名或移除。
[API 契约](/api/) 列出了每个站点参数、front matter 参数、CSS 钩子和扩展点。
其中未列出的内容均属内部实现，可随时更改而不另行通知。

> 详细技术文档目前仅有英文版；上述 `/config-example/`、`/api/` 链接指向英文原文。
