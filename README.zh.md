# hugo-theme-sigil

[English](README.md) | 中文 | [日本語](README.ja.md)

**一个简约的文学向 [Hugo](https://gohugo.io/) 主题：旧纸底色，三种墨色，排印退居内容之后。**

[![Hugo Themes](https://img.shields.io/badge/Hugo--Themes-@sigil-blue)](https://themes.gohugo.io/themes/hugo-theme-sigil/)
[![Minimum Hugo Version](https://img.shields.io/static/v1?label=Hugo&message=v0.156.0%2B&color=blue&logo=hugo)](https://github.com/gohugoio/hugo/releases)
[![Release](https://img.shields.io/github/v/tag/ouatis/hugo-theme-sigil?sort=semver&label=release)](https://github.com/ouatis/hugo-theme-sigil/releases)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> 基于 [PaperMod](https://github.com/adityatelange/hugo-PaperMod) 深度定制——
> 为何单独立项见[下文说明](#与-papermod-的分野)。

|  |  |
| --- | --- |
| **在线演示** | <https://ouatis.com/hugo-theme-sigil/> |
| **排版展示页** | <https://ouatis.com/hugo-theme-sigil/posts/typography/> |
| **示例站源码** | [exampleSite/](exampleSite/) |

![Screenshot](https://raw.githubusercontent.com/ouatis/hugo-theme-sigil/main/images/screenshot.png)

---

## 特性

`∴ 朱砂回应 · 墨绿说明 · 琥珀点亮`

- **Tufte 式边注** -- 宽屏（≥1280px）脚注排入引注右侧的边距，窄屏自动回退文末。
- **圆形揭示的主题切换** -- 暗色从点击处扩散展开（View Transitions API），不支持时退为柔和过渡。
- **幽灵年份归档** -- 归档页的年份是背景里的大号数字。
- **全文 RSS** -- 订阅里读全文，不是摘要。
- **CJK 字体子集** -- `build-fonts.sh` 按 unicode-range 切片输出 IBM Plex woff2，读者只下载几 KB。
- **三色体系** -- 朱砂、墨绿、琥珀，再无第四色。
- **PaperMod 基本盘** -- Fuse.js 搜索、分类标签、面包屑、目录、代码复制按钮、OG / Twitter / Schema 元数据，内置 zh-CN / en / ja 文案。

## 安装

先跑示例站试试：

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

在自己的站点使用：

```bash
# 以 git 子模块方式（CI 部署推荐）
git submodule add https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# 或直接克隆
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
```

```toml
# hugo.toml
theme = "hugo-theme-sigil"
```

部署前把 `baseURL` 改成自己的域名（示例站默认 `https://example.com/`）。

## 配置

主题自有参数：

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `sgKicker` | 不显示 | 首页标题上方的小字 |
| `sgReading` / `sgPlaying` / `sgMotto` | 不显示 | Hero 印章下方的轮换状态 |
| `sgSealImage` | ∴ 字形 | 首页徽记图片 |
| `ShowFullTextinRSS` | `false` | RSS 输出全文 |
| `ShowAllPagesInArchive` | `false` | 归档收录全部页面而非仅文章 |
| `disableLangToggle` | `false` | 隐藏语言切换 |
| `disableSpecial1stPost` | `false` | 首页首条不再使用特殊样式 |

继承自 PaperMod 的常用参数原样可用：

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `defaultTheme` | `auto` | `light` / `dark` / `auto` |
| `ShowToc` / `TocOpen` | `false` | 文章目录 |
| `ShowCodeCopyButtons` | `false` | 代码块复制按钮 |
| `ShowBreadCrumbs` | `false` | 文章面包屑 |
| `ShowReadingTime` / `ShowWordCount` | `false` | 文章 meta |
| `ShowPostNavLinks` | `false` | 上一篇 / 下一篇 |
| `showRelated` | `true` | 文末相关文章 |
| `editPost` | 不显示 | 文末"编辑"链接（`URL`、`Text`） |
| `socialIcons` | 不显示 | 社交图标；github / rss / steam 走 Phosphor，其余回退内置图标集 |
| `homeInfoParams` / `profileMode` | — | 首页模式及其内容 |
| `hideFooter`、`hideMeta`、`hideSummary` 等 | `false` | 页面级覆盖 |

边注、归档背景年份、圆形揭示的主题切换均为自动行为，无需配置。完整示例见
[exampleSite/hugo.toml](exampleSite/hugo.toml)。示例站内容为英文；主题内置 zh-CN / en / ja 文案。

## 字体与边注

首次构建前运行：

```bash
pip install "fonttools[woff]"
scripts/build-fonts.sh
```

脚本按站内用字生成 unicode-range 切片的 woff2 分片，读者首访按需下载几 KB；未运行则回退系统字体。脚注在宽屏（≥1280px）呈现在引注右侧的边距里（Tufte 式），窄屏自动回退文末。

## 性能

线上 demo 实测：无障碍 100 · 最佳实践 96 · CLS 0
（[Lighthouse](https://developer.chrome.com/docs/lighthouse/)，移动端）。也可在
[PageSpeed Insights](https://pagespeed.web.dev/report?url=https%3A%2F%2Fouatis.com%2Fhugo-theme-sigil%2F)
自行复测。

## 与 PaperMod 的分野

Sigil 是 PaperMod 的深度定制，但以下差异不适合回传上游，因此单独立项：

- **Tufte 式边注**：宽屏下脚注克隆进引注旁的边距，窄屏回退文末。
- **圆形揭示的主题切换**：暗色经由 View Transitions API 从点击处圆形展开，并带柔和回退。
- **幽灵年份归档**：归档页把年份排成背景大字，而非表头行。
- **全文 RSS 与字体子集管线**：`build-fonts.sh` 按 unicode-range 生成 IBM Plex 切片，CJK 读者下载 KB 而非 MB。
- 严格的三色文学设计体系（朱砂 / 墨绿 / 琥珀）与 zh-CN 优先的多语言文案。

## 许可

MIT — 见 [LICENSE](LICENSE)。

基于 [PaperMod](https://github.com/adityatelange/hugo-PaperMod) · 字体
[IBM Plex](https://github.com/IBM/plex)（SIL OFL 1.1）· 图标
[Phosphor Icons](https://phosphoricons.com/)（MIT）· 搜索
[Fuse.js](https://github.com/krisk/fuse)（Apache-2.0）
