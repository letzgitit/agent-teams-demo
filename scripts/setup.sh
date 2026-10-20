#!/bin/bash
# 가상환경 만들고 의존성 설치 + 정상 테스트 실행
cd "$(dirname "$0")/.." || exit 1
python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt && .venv/bin/python -m pytest -q
