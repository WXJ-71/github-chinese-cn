#!/bin/sh
# 从上游同步脚本 / 词库 / LICENSE，并重新打上 @require 补丁。
# 用法：sh sync.sh   （之后 git add -A && git commit && git push）
set -e

BASE=${BASE:-https://cdn.jsdelivr.net/gh/maboloshi/github-chinese@gh-pages}
HOST=${HOST:-https://wxj-71.github.io/github-chinese-cn}

echo "上游: $BASE"
curl -fsSL -o main.user.js "$BASE/main.user.js"
curl -fsSL -o locals.js    "$BASE/locals.js"
curl -fsSL -o LICENSE      "$BASE/LICENSE"

VERSION=$(sed -n 's|^// @version *||p' main.user.js | head -1)
echo "上游版本: $VERSION"

python3 - "$HOST" "$VERSION" <<'PY'
import datetime
import pathlib
import re
import sys

host, version = sys.argv[1], sys.argv[2]
path = pathlib.Path('main.user.js')
text = path.read_text(encoding='utf-8')

# 1) 词库改到自托管地址（GPL 允许，需在文件头声明改动）
patched, count = re.subn(
    r'// @require\s+https://raw\.githubusercontent\.com/\S+',
    f'// @require      {host}/locals.js?v{version}', text, count=1)
if count != 1:
    raise SystemExit('✗ 没有找到 @require 行，上游结构可能变了，请手动检查')

# 2) 改动声明
notice = f"""/* ---------------------------------------------------------------------------
 * 【改动声明 / NOTICE OF MODIFICATION】
 * 本文件是 https://github.com/maboloshi/github-chinese 的再分发副本，许可 GPL-3.0。
 * 相对上游 gh-pages 分支的唯一改动：把词库的 @require 地址从
 *   https://raw.githubusercontent.com/maboloshi/github-chinese/gh-pages/locals.js
 * 改为本仓库自托管地址
 *   {host}/locals.js
 * 原因是 raw.githubusercontent.com 在中国大陆多数网络下无法直连，照原样安装会
 * 出现「装上了但界面没有汉化」。脚本逻辑与词库内容均与上游一致。
 * 上游版本：{version}            改动日期：{datetime.date.today().isoformat()}
 * 同步上游：见本仓库 README / sync.sh
 * ------------------------------------------------------------------------- */
"""
if 'NOTICE OF MODIFICATION' not in patched:
    patched = patched.replace('// ==/UserScript==\n', '// ==/UserScript==\n\n' + notice, 1)

path.write_text(patched, encoding='utf-8')
print(f'@require -> {host}/locals.js?v{version}')
PY

python3 - "$HOST" <<'PY2'
# 由 main.user.js + locals.js 生成单文件版 all-in-one.user.js：
#   * 去掉 @require（词库内联，任何脚本管理器都能跑，包括 Via 的内置管理器）
#   * 补一层 GM 接口垫片（Via 等简易引擎缺少 GM_* 时自动补齐）
import pathlib
import re

main = pathlib.Path('main.user.js').read_text(encoding='utf-8')
dictionary = pathlib.Path('locals.js').read_text(encoding='utf-8')

shim = '''/* ===== GM 接口垫片（Via 等简易脚本引擎缺少以下接口时自动补齐） ===== */
(function () {
  var store = window.localStorage, ns = function (k) { return 'gm:' + k; };
  if (typeof GM_addStyle === 'undefined') window.GM_addStyle = function (css) {
    var s = document.createElement('style'); s.textContent = css;
    (document.head || document.documentElement).appendChild(s); return s;
  };
  if (typeof GM_getValue === 'undefined') window.GM_getValue = function (k, d) {
    try { var v = store.getItem(ns(k)); return v === null ? d : JSON.parse(v); } catch (e) { return d; }
  };
  if (typeof GM_setValue === 'undefined') window.GM_setValue = function (k, v) {
    try { store.setItem(ns(k), JSON.stringify(v)); } catch (e) {}
  };
  if (typeof GM_xmlhttpRequest === 'undefined') window.GM_xmlhttpRequest = function (o) {
    fetch(o.url, { method: o.method || 'GET', headers: o.headers || {}, body: o.data })
      .then(function (r) { return r.text().then(function (t) { return { r: r, t: t }; }); })
      .then(function (x) { if (o.onload) o.onload({ status: x.r.status, responseText: x.t, response: x.t, finalUrl: o.url }); })
      .catch(function (e) { if (o.onerror) o.onerror(e); });
  };
  if (typeof GM_registerMenuCommand === 'undefined') window.GM_registerMenuCommand = function () { return 0; };
  if (typeof GM_unregisterMenuCommand === 'undefined') window.GM_unregisterMenuCommand = function () {};
  if (typeof GM_notification === 'undefined') window.GM_notification = function () {};
})();
/* ===== 垫片结束 ===== */
'''

body = re.sub(r'// @require[^\n]*\n', '// (词库已内联在本文件中，无需 @require)\n', main, count=1)
marker = '// ==/UserScript==\n'
cut = body.index(marker) + len(marker)
out = (body[:cut] + '\n' + shim
       + '\n/* ===== 以下为内联词库 locals.js（与上游一致，未改动） ===== */\n'
       + dictionary + '\n/* ===== 词库结束 ===== */\n' + body[cut:])
pathlib.Path('all-in-one.user.js').write_text(out, encoding='utf-8')
print('all-in-one.user.js: %.2f MB' % (len(out.encode()) / 1048576))
PY2

echo "完成。检查 diff 后提交："
echo "  git add -A && git commit -m 'sync upstream $VERSION' && git push"
