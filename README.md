# hugo-theme-sigil

中文 | [English](README.en.md) | [日本語](README.ja.md)

**A literary Hugo theme — ink, paper, and everything in threes.**

> [!IMPORTANT]
> **本主题明确面向中文写作者。** 字体管线、排印参数、栏宽与行高，
> 全部围绕中文阅读体验构建。其他语言可用，但设计与优化均以中文阅读体验为先。
> (For English, see [README.en.md](README.en.md); 日本語は [README.ja.md](README.ja.md)。)

一个面向中文写作者的文学 Hugo 主题：旧纸底色、朱砂·墨绿·琥珀三色体系、IBM Plex Sans CJK 排印、
Tufte 式边注、全文 RSS 与按内容自动切片的字体子集管线。基于 [PaperMod](https://github.com/adityatelange/hugo-PaperMod)（MIT）深度定制。

![Screenshot](docs/screenshot.png)

## 特性 / Features

- **三色体系**：朱砂（交互）· 墨绿（元信息）· 琥珀（高亮），明暗双主题
- **Tufte 式边注**：宽屏下脚注出现在引注右侧的边距里，窄屏自动回退文末
- **字体子集管线**：`scripts/build-fonts.sh` 按 IBM Plex Sans、Chinese SC、Japanese 官方分片准备站内用字，首访只下载按需分片
- **全文 RSS**
- **输入即搜**（fuse）
- **归档 / 分类 / 标签 / 面包屑 / 阅读进度**
- **多语言**：内置 zh-CN / en / ja 文案
- **纸纹底、页脚三段式落款、悬停涟漪**等细节

## 快速开始 / Quick start

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

在自己的站点使用：

```bash
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# hugo.toml:
# theme = "hugo-theme-sigil"
```

## 配置 / Configuration

| 参数 | 说明 | 默认 |
| --- | --- | --- |
| `params.sgKicker` | 首页眉标（大标题上方的小字） | 不显示 |
| `params.sgColophon` | 页脚题词（三段式的中段） | 不显示 |
| `params.sgSealImage` | 首页徽记图片；不设则显示默认的 ∴ 字形印章 | ∴ 字形 |
| `params.mainSections` | 首页列表与 RSS 的内容区段 | `["posts"]` |
| `params.author` | 文章署名（RSS 与文章 meta 使用） | 不显示 |

完整示例见 [exampleSite/hugo.toml](exampleSite/hugo.toml)。示例站只展示中文页面；主题本身支持 zh-CN、en、ja 多语言配置。

## 字体子集 / Font subsetting

主题使用 IBM Plex Sans 系列字体（普通拉丁、Chinese SC、Japanese，IBM 开源字体许可）。中文页面优先使用 IBM Plex Sans SC，日文页面优先使用 IBM Plex Sans JP。首次构建前运行：

```bash
pip install "fonttools[woff]"
scripts/build-fonts.sh
```

脚本会扫描站内全部用字并生成按 unicode-range 切片的 woff2 分片——
读者首访只需按需下载几 KB，而不是 20MB 的整包字体。未运行时自动回退系统无衬线字体。

## 边注 / Sidenotes

文章中的脚注在宽屏（≥1440px）自动呈现为引注右侧的边注（Tufte 式），
悬停引注与边注会互相提亮；窄屏回退为文末脚注；打印时恢复文末列表；
不支持 `:has` 的旧浏览器保持原生脚注形态。

## 致谢 / Credits

基于 [PaperMod](https://github.com/adityatelange/hugo-PaperMod)（MIT）。
字体：[IBM Plex](https://github.com/IBM/plex)（IBM 开源字体许可）。

## License

MIT — 详见 [LICENSE](LICENSE)。
