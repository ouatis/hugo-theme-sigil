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
- 搜索、分类、标签、面包屑、目录、代码复制和多语言字符串

## 安装

```bash
git submodule add https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
```

```toml
# hugo.toml
theme = "hugo-theme-sigil"
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
| `ShowFullTextinRSS` | `false` | RSS 输出全文 |
| `ShowAllPagesInArchive` | `false` | 归档包含所有页面 |
| `homePageSize` | 全部 | 首页每页文章数 |

完整示例见 [exampleSite/hugo.toml](exampleSite/hugo.toml)。

## 字体

仓库已包含拉丁字母 IBM Plex 字体。重新生成 CJK 子集：

```bash
bash scripts/build-fonts.sh
# 或
python scripts/build-fonts.py
```

## 许可证

MIT，详见 [LICENSE](LICENSE)。

基于 PaperMod；字体使用 IBM Plex（SIL OFL 1.1），图标使用 Phosphor
Icons（MIT），搜索使用 Fuse.js（Apache-2.0）。
