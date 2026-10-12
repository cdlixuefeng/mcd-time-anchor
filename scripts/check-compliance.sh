# 参赛合规自检：必备文件 / 凭证泄露 / 外链白名单 / 声明一致性
# 用法: bash scripts/check-compliance.sh
set -uo pipefail
cd "$(dirname "$0")/.."
PY="C:/Users/Administrator/.workbuddy/binaries/python/versions/3.13.12/python.exe"
FAIL=0

echo "=== 1. 参赛必备文件 ==="
for f in README.md CONTEST_DECLARATION.md MCP_INTEGRATION.md mcp-config.example.json; do
  if [ -f "$f" ]; then echo "  ✓ $f"; else echo "  ✗ 缺失: $f"; FAIL=1; fi
done
[ -f workbuddy.md ] && echo "  ✓ workbuddy.md（WorkBuddy 专项奖材料）" || { echo "  ✗ 缺失 workbuddy.md"; FAIL=1; }
[ -f skill/SKILL.md ] && echo "  ✓ skill/SKILL.md（源代码）" || { echo "  ✗ 缺失源代码"; FAIL=1; }

echo "=== 2. 凭证泄露扫描 ==="
if grep -rInE "(gho_|ghp_|Bearer [A-Za-z0-9]{20,}|MCD[A-Z0-9]{16,})" --exclude-dir=.git . 2>/dev/null | grep -v "scripts/check-compliance.sh"; then
  echo "  ✗ 发现疑似真实凭证"; FAIL=1
else
  echo "  ✓ 未发现 Token / 密钥 / 凭证"
fi
if [ -f mcp-config.example.json ]; then
  grep -q '\${MCD_MCP_TOKEN}' mcp-config.example.json && echo "  ✓ 配置仅含环境变量占位符" || { echo "  ✗ 占位符缺失"; FAIL=1; }
fi

echo "=== 3. 外链白名单 ==="
ALLOW="github.com|open.mcd.cn|lbs.amap.com|lbsyun.baidu.com|workbuddy.cn|img.shields.io|mcd.cn|m.mcd.cn|mcp.mcd.cn"
BAD=$(grep -rohE "https?://[a-zA-Z0-9.-]+" --include="*.md" --include="*.json" --include="*.html" . 2>/dev/null | grep -v "^\$" | sed 's|https\?://||' | sort -u | grep -vE "^($ALLOW)" || true)
if [ -n "$BAD" ]; then echo "  ⚠ 非白名单域名（人工确认）:"; echo "$BAD" | sed 's/^/    - /'; else echo "  ✓ 全部外链在白名单内"; fi

echo "=== 4. CONTEST_DECLARATION 与官方一致性 ==="
if command -v curl > /dev/null && [ -f CONTEST_DECLARATION.md ]; then
  curl -s --max-time 15 --proxy http://127.0.0.1:10808 \
    https://raw.githubusercontent.com/M-China/mcd-developer-innovation-challenge/main/CONTEST_DECLARATION.md > .official-decl.md 2>/dev/null || true
  if [ -s .official-decl.md ]; then
    "$PY" - <<'PYEOF'
import hashlib, re
def norm(p):
    s = open(p, encoding='utf-8').read()
    return re.sub(r'\s+', '', s)
a, b = norm('CONTEST_DECLARATION.md'), norm('.official-decl.md')
print("  ✓ 与官方原文一致" if a == b else "  ✗ 与官方原文存在差异，必须原样复制！")
PYEOF
  else
    echo "  - 无法拉取官方原文（网络），跳过比对"
  fi
  rm -f .official-decl.md
fi

echo "=== 5. 仓库资产 ==="
for f in assets/viewer-demo.png assets/demo-flow.gif web/time-anchor-viewer.html demo/animated-demo.html demo/memory-profile.example.json docs/ISSUE_TEMPLATE.md docs/PROMO.md; do
  [ -f "$f" ] && echo "  ✓ $f" || { echo "  ✗ 缺失: $f"; FAIL=1; }
done

echo
[ "$FAIL" -eq 0 ] && echo "✅ 合规自检通过" || echo "❌ 存在必须修复的问题"
exit $FAIL
