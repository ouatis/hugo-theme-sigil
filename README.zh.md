# hugo-theme-sigil

[English](README.md) | 中文 | [日本語](README.ja.md)

一个简约的 Hugo 博客主题：旧纸底色、朱砂·墨绿·琥珀三色排印、Tufte 式边注、
全文 RSS 与按内容切片的字体子集管线。基于 [PaperMod](https://github.com/adityatelange/hugo-PaperMod)（MIT）深度定制。

**[在线演示](https://ouatis.com/hugo-theme-sigil/)**

![Screenshot](docs/screenshot.png)

## 快速开始

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

在自己的站点使用：

```bash
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# hugo.toml: theme = "hugo-theme-sigil"
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

## 许可

MIT — 见 [LICENSE](LICENSE)。基于 [PaperMod](https://github.com/adityatelange/hugo-PaperMod)；字体 [IBM Plex](https://github.com/IBM/plex)（IBM 开源字体许可）；图标 [Phosphor Icons](https://phosphoricons.com/)（MIT）。
