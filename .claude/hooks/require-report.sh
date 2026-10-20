#!/bin/bash
# TaskCompleted 훅: 팀원이 review/<이름>.md 를 쓰기 전에는 작업을 완료로 못 넘긴다.
# 입력은 stdin JSON(teammate_name 등). exit 2 = 완료 막기 + stderr 가 모델에 전달됨.
command -v jq >/dev/null || { echo "jq 가 필요하다 (brew install jq)" >&2; exit 1; }
input=$(cat)
name=$(echo "$input" | jq -r '.teammate_name // empty')
[ -z "$name" ] && exit 0                       # 리더가 끝낸 작업은 통과
dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
f="$dir/review/${name}.md"
if [ ! -s "$f" ]; then
  echo "review/${name}.md 가 비어 있다. '파일:줄 · 문제 · 왜 · 고칠 방향' 형식으로 먼저 쓰고 완료하라." >&2
  exit 2
fi
exit 0
