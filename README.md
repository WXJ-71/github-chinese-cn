# github-chinese-cn

[GitHub 中文化插件](https://github.com/maboloshi/github-chinese) 的**自托管再分发副本**，
只改了一处：词库的加载地址。

上游脚本的词库用 `@require` 从 `raw.githubusercontent.com` 取，而该域名在中国大陆多数网络下
无法直连，照原样安装会出现「装上了、但界面完全没汉化」（脚本里没有备用源）。本仓库把词库和
脚本一起放在 GitHub Pages 上，安装地址因此在国内网络下可用。

- 上游项目：<https://github.com/maboloshi/github-chinese>（34k★，GPL-3.0）
- 上游版本：`1.9.4.4-2026-09-27`
- 本副本改动：**仅** `@require` 一行 + 文件头的改动声明；脚本逻辑与词库内容与上游一致

## 安装

### 1. 装一个用户脚本管理器

| 平台 | 推荐 |
| --- | --- |
| 安卓 | **Via 浏览器**（自带脚本管理器，上游兼容列表里点名支持）；或 Firefox 安卓 + Violentmonkey / Tampermonkey |
| 电脑 | Edge / Chrome / Firefox + Tampermonkey 或 Violentmonkey |

### 2. 安装脚本

打开这个地址，确认安装：

```
https://wxj-71.github.io/github-chinese-cn/main.user.js
```

### 3. 打开 GitHub

<https://github.com/> 的菜单、按钮、设置项即变为中文。

首次安装会拉取约 2 MB 词库（实测约 40 KB/s，**大概 1 分钟**），脚本管理器会缓存它，
之后不再下载。若首屏没变化，刷新一次页面。

## 各地址在国内的可用性（实测）

| 地址 | 可用性 |
| --- | --- |
| `greasyfork.org`（最常用的脚本源） | ✗ 不可直连 |
| `raw.githubusercontent.com`（上游词库） | ✗ 不可直连 |
| `chromewebstore.google.com` | ✗ 不可直连 |
| `cdn.jsdelivr.net` | ✓ 可用（约 40 KB/s） |
| **`<用户名>.github.io`（本仓库 Pages）** | ✓ 可用（约 40 KB/s） |

想跟随上游自动更新词库的话，把 `main.user.js` 第 15 行的 `@require` 换成
`https://cdn.jsdelivr.net/gh/maboloshi/github-chinese@gh-pages/locals.js` 即可
（jsDelivr 会定期回源，缺点是多了第三方依赖）。

## 同步上游

```sh
sh sync.sh          # 重新下载上游脚本/词库/LICENSE，并自动重打 @require 补丁
git add -A && git commit -m "sync upstream" && git push
```

## 许可

[GPL-3.0](LICENSE)，与上游一致。本仓库仅为再分发，版权归原作者（楼教主 / 沙漠之子）所有；
按 GPL 要求，`main.user.js` 文件头注明了改动内容与日期。
