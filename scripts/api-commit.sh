#!/usr/bin/env bash
# 通过 GitHub Git Data API 提交文件（绕过本机 git push 网络问题）
# 用法: bash scripts/api-commit.sh "<commit message>" <file1> <file2> ...
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="cdlixuefeng/mcd-time-anchor"
MSG="$1"; shift
FILES=("$@")
PY="C:/Users/Administrator/.workbuddy/binaries/python/versions/3.13.12/python.exe"
TMP=".apitmp"
mkdir -p "$TMP"

BASE=$(gh api "repos/$REPO/git/ref/heads/main" --jq '.object.sha')
BASE_TREE=$(gh api "repos/$REPO/commits/$BASE" --jq '.commit.tree.sha')
echo "base: ${BASE:0:7}  tree: ${BASE_TREE:0:7}"

TREE_ENTRIES="[]"
for f in "${FILES[@]}"; do
  if [[ "$f" =~ \.(md|json|html|txt|cjs|sh)$ ]]; then
    "$PY" -c "import json,sys;open(sys.argv[2],'w',encoding='utf-8').write(json.dumps({'content':open(sys.argv[1],encoding='utf-8').read(),'encoding':'utf-8'}))" "$f" "$TMP/blob.json"
  else
    "$PY" -c "import json,sys,base64;open(sys.argv[2],'w',encoding='utf-8').write(json.dumps({'content':base64.b64encode(open(sys.argv[1],'rb').read()).decode(),'encoding':'base64'}))" "$f" "$TMP/blob.json"
  fi
  SHA=$(gh api "repos/$REPO/git/blobs" --input "$TMP/blob.json" --jq '.sha')
  echo "blob: $f -> ${SHA:0:7}"
  TREE_ENTRIES=$("$PY" -c "import json,sys;e=json.loads(sys.argv[1]);e.append({'path':sys.argv[2],'mode':'100644','type':'blob','sha':sys.argv[3]});print(json.dumps(e))" "$TREE_ENTRIES" "$f" "$SHA")
done

"$PY" -c "import json,sys;open(sys.argv[3],'w',encoding='utf-8').write(json.dumps({'base_tree':sys.argv[1],'tree':json.loads(sys.argv[2])}))" "$BASE_TREE" "$TREE_ENTRIES" "$TMP/tree.json"
NEW_TREE=$(gh api "repos/$REPO/git/trees" --input "$TMP/tree.json" --jq '.sha')
echo "new tree: ${NEW_TREE:0:7}"

"$PY" -c "import json,sys;open(sys.argv[3],'w',encoding='utf-8').write(json.dumps({'message':sys.argv[1],'tree':sys.argv[2],'parents':[sys.argv[4]]}))" "$MSG" "$NEW_TREE" "$TMP/commit.json" "$BASE"
NEW_COMMIT=$(gh api "repos/$REPO/git/commits" --input "$TMP/commit.json" --jq '.sha')
echo "new commit: ${NEW_COMMIT:0:7}"

"$PY" -c "import json,sys;open(sys.argv[2],'w',encoding='utf-8').write(json.dumps({'sha':sys.argv[1],'force':False}))" "$NEW_COMMIT" "$TMP/ref.json"
gh api -X PATCH "repos/$REPO/git/refs/heads/main" --input "$TMP/ref.json" > /dev/null
rm -rf "$TMP"
echo "OK: main -> ${NEW_COMMIT:0:7}"
