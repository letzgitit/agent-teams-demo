#!/bin/bash
# 녹화 사이사이 초기화: review/ 결과와 DB, 캐시를 지운다. 코드는 건드리지 않는다.
cd "$(dirname "$0")/.." || exit 1
rm -f review/*.md todos.db
rm -rf .pytest_cache
find . -name __pycache__ -not -path "./.venv/*" -exec rm -rf {} + 2>/dev/null
touch review/.gitkeep
echo "초기화 완료. 코드 상태 확인:"
git status --short
