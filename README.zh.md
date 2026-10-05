# hugo-theme-sigil

**[English](README.md)** | 中文 | [日本語](README.ja.md)

一个面向 [Hugo](https://gohugo.io/) 的克制型文学主题，基于
[PaperMod](https://github.com/adityatelange/hugo-PaperMod)。

演示站：<https://ouatis.com/hugo-theme-sigil/>

## 特性

- 宽屏 Tufte 风格旁注，窄屏自动转为尾注
- Ghost-year 年份归档
- 圆形展开式暗色模式切换
- RSS 输出全文
- IBM Plex 字体与 CJK 字体子集
- JSON Feed 1.1(`/feed.json`,与 RSS 并存,构建期自动生成)
- 搜索、分类、标签、面包屑、目录、代码复制和多语言字符串
- 页面级可选:KaTeX 数学(已同捆)、Mermaid 图表(定版 CDN)、图片灯箱(glightbox,已同捆)
- 用文章标题自动生成 OG 卡片图(`images.Text`,仅构建期)
- 外链门形记号由渲染钩子按主机名判定,不写死任何域名
- `llms.txt`(可选 `llms-full.txt`)——面向 AI Agent 的机器可读站点索引
- 维护者与 Agent 请读 [AGENTS.md](AGENTS.md):构建/验证命令与已知坑;`scripts/check.sh` 是一条命令的完整验证

## 安装

以 git 子模块安装：

```bash
git submodule add https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
```

```toml
# hugo.toml
theme = "hugo-theme-sigil"
```

或以 [Hugo module](https://gohugo.io/hugo-modules/) 安装：

```bash
hugo mod init github.com/you/your-site   # 站点已有 go.mod 则跳过
```

```toml
# hugo.toml
[module]
  [[module.imports]]
    path = "github.com/ouatis/hugo-theme-sigil"
```

预览示例站：

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

## 配置

PaperMod 的常用配置可以继续使用。Sigil 专属配置：

| 参数 | 默认值 | 用途 |
| --- | --- | --- |
| `sgKicker` | 隐藏 | 首页标题上方文字 |
| `sgHomeTitle` | 站点标题 | 首页标题 |
| `sgReading` / `sgPlaying` / `sgMotto` | 隐藏 | 首页状态文字 |
| `sgSealImage` | `∴` | 首页印章图片 |
| `sgDaysInCage` | `false` | 状态条天数计数「Day N in the Cage」,从最早一篇起算 |
| `ShowFullTextinRSS` | `false` | RSS 输出全文 |
| `ShowAllPagesInArchive` | `false` | 归档包含所有页面 |
| `homePageSize` | 全部 | 首页每页文章数 |
| `sgSeriesFrom` | 隐藏 | 系列导航:指向策展页,其正文列表即阅读顺序(含未写占位);`sgSeriesTab` 定页签短标 |
| `math` / `mermaid` / `lightbox` | `false` | 页面 frontmatter 或站点级开启:KaTeX 数学、Mermaid 图表、图片灯箱;未开启的页面零加载。`$$…$$` 开箱即用;行内 `\(…\)` 需另启用 goldmark passthrough(见 [exampleSite/hugo.toml](exampleSite/hugo.toml)) |
| `ogAutoCard` | `false` | 无封面/图片的文章,构建期用标题+站名排一张 1200×630 的 OG 卡片(纸底∴) |
| `ogCardFont` | 内附 Plex Serif | OG 卡片字体的 `resources.Get` 路径(TTF)。内附拉丁字体画不了汉字——中日站点应为标题用字做子集 TTF 并指向它 |
| `analytics.*` | 隐藏 | 第三方统计(仅生产环境):`analytics.plausible.domain`、`analytics.umami`(`src` + `id`)、`analytics.goatcounter.code`、`analytics.fathom.site` |
| `llmsTxtIntro` | 隐藏 | `llms.txt` 里可选的一段站点导语 |

### Agent 可读输出(llms.txt)

把 `LLMSTXT`(页面与文章索引)与可选的 `LLMSFULL`(同一头部,其后逐篇全文)
加进 home outputs 即启用:

```toml
[outputs]
  home = ["HTML", "RSS", "JSONFeed", "LLMSTXT", "LLMSFULL"]
```

关键页面一节自动探测 关于/归档/词目/RSS;要手工策展就覆盖
`layouts/home.llmstxt.txt`。

完整示例见 [exampleSite/hugo.toml](exampleSite/hugo.toml)。

## 字体

仓库已包含拉丁字母 IBM Plex 字体。重新生成 CJK 子集：

```bash
bash scripts/build-fonts.sh
# 或
python scripts/build-fonts.py
```

## 性能

以示例站 minify 构建实测：

- 首页合计约 **78 KB**：HTML 16 KB + CSS 57 KB + 内联 JS 5 KB，**零外链 JavaScript**
- 可选项按需加载：搜索脚本 18 KB（仅搜索页）、KaTeX 332 KB（`math = true`）、glightbox 56 KB（`lightbox = true`）
- 字体：文字密集页首访约 **56 KB**（4 片拉丁子集；示例站的中文回退系统字体）。CJK 站点走语料子集管线时，整站字符集一次性下载（约 1.3 MB）——有意不做分片：一个文件全站缓存一次到位，`font-display: swap` 兜底等待
- 无框架、无 jQuery、无运行时 CDN 依赖

## 稳定性

公开契约——参数名、`sg-*` 类名、输出格式、数据结构、扩展 partial——自
**v0.9.0 起冻结**：改名须留弃用窗口，移除等到大版本。完整契约与弃用政策见
[docs/api.md](docs/api.md)。两种安装方式（submodule 与 Hugo module）均有 CI 覆盖。

## 翻译

内置的 47 门语言大部分由机器补全。母语者的修订非常欢迎——开 issue 或提交只动 `i18n/*.yaml` 的 PR 即可；新键先入 `en`,其余语言自动回落。

## 许可证

MIT，详见 [LICENSE](LICENSE)。

基于 PaperMod；字体使用 IBM Plex（SIL OFL 1.1），图标使用 Phosphor
Icons（MIT），搜索使用 Fuse.js（Apache-2.0），数学排版使用 KaTeX（MIT，已同捆），
灯箱使用 glightbox（MIT，已同捆），图表使用 Mermaid（MIT，按需经定版 CDN 加载）。
