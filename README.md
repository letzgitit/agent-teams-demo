# techday-agent-teams-demo

Claude Code Agent Teams 녹화용 작은 예제. 할 일(Todo) Flask 앱에 **버그 3개를 일부러 심어 두었다**(보안·성능·테스트). 읽기 전용 리뷰어 3명이 각자 렌즈로 찾는 장면을 찍는 용도다. 실서비스 코드가 아니다.

> 이 저장소의 `.claude/settings.json` 은 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 을 켠다. 받아서 쓰면 이 폴더에서 팀 기능이 켜진다(실험 기능, 토큰을 많이 쓴다).

## 준비

```bash
scripts/setup.sh            # .venv 생성 + 설치 + 정상 테스트(3개 통과해야 함)
brew install jq             # 훅 스크립트가 쓴다
```

정답지는 `docs/ANSWER_KEY.md` — **녹화 화면에 띄우지 말 것.** 버그가 실제로 있는지 확인: `.venv/bin/python -m pytest -q docs/verify_bugs.py` (4개 실패가 정상).

## 구성

| 경로 | 역할 |
|---|---|
| `app/` | Flask 앱 (`routes.py` 에 버그 3개) |
| `tests/` | 정상 기능 테스트 (통과) |
| `.claude/agents/` | 리뷰어 정의 3개 (`security-reviewer` · `perf-reviewer` · `test-reviewer`, 읽기 도구 + `Write`, sonnet) |
| `.claude/settings.json` | 팀 기능 환경변수, 허용 목록, `TaskCompleted` 훅 |
| `.claude/hooks/require-report.sh` | `review/<팀원 이름>.md` 가 비어 있으면 완료를 막는다(exit 2) |
| `review/` | 리뷰어 결과가 쌓이는 폴더 (`*.md` 는 git 무시) |
| `scripts/reset.sh` | 녹화 사이사이 초기화 |

## 녹화 순서 (요약)

1. `scripts/reset.sh` → 터미널 글자 크게, 알림 끄기, 시작 배너(계정 줄)는 편집에서 컷.
2. 편집기에 `.claude/agents/*.md` → `settings.json` → 훅 스크립트를 차례로 보여 준다.
3. 이 폴더에서 `claude` 실행(처음이면 폴더 신뢰 허용) → 아래 프롬프트 붙여 넣기.
4. 팀원이 뜨면 `Ctrl+T`로 작업 목록, 팀원을 골라 직접 메시지.
5. 훅 장면: tests 팀원에게 「결과 파일 쓰기 전에 작업부터 완료로 표시해 봐」.
6. 리더 요약이 나오면 `docs/ANSWER_KEY.md` 표와 대조(편집에서 옆에 붙인다).
7. 팀원 종료 → 끝나면 환경변수를 `0` 으로 되돌리고 `scripts/reset.sh`.

## 리더에게 붙여 넣을 프롬프트

```text
이 저장소를 리뷰할 팀을 만들어. 팀원 3명을 Sonnet으로 띄워: 이름 security 는 security-reviewer 타입, perf 는 perf-reviewer 타입, tests 는 test-reviewer 타입. 각자 자기 렌즈만 보고 review/<이름>.md 에 결과를 써. 서로의 지적에서 틀린 게 보이면 직접 반박해. 리더는 직접 리뷰하지 말고 셋이 끝날 때까지 기다린 다음, 겹치는 지적을 합쳐 심각한 순서로 5줄 요약해. 끝나면 팀원 셋 다 종료시켜.
```

## 초기화

```bash
scripts/reset.sh                       # review/ 결과와 DB 지움
git status --short                     # 코드가 바뀌었으면
git reset --hard <첫 커밋>             # 첫 커밋 상태로 완전히 되돌림 (git log 로 해시 확인)
```

## 알아 둘 것

- 리뷰어는 `Edit` 이 없고 `Write` 는 `review/**` 만 자동 허용이다. 그 밖에 쓰려 하면 리더 화면에 확인 창이 뜬다(촬영 중 뜨면 거절).
- `permissions.deny` 로 `docs/` 읽기를 막았지만 Grep 까지 완전히 막지는 못한다. 정답지를 다른 곳에 옮겨 찍고 싶으면 `docs/` 를 저장소 밖으로 빼도 된다.
- 이 폴더는 로컬 전용이다. 공개 전에 발표자가 한 번 더 확인한다.
