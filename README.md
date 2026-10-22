# techday-agent-teams-demo

Claude Code **Agent Teams** 데모 저장소. 할 일(Todo) Flask 앱에 **버그 3개를 일부러 심어 두었고**(보안·성능·테스트), 읽기 전용 리뷰어 3명이 각자 렌즈로 그 버그를 찾고 서로의 지적을 교차 검토하는 장면을 보여 준다. 실서비스 코드가 아니다.

- **역할 경계를 설정으로 강제한다.** 리뷰어 정의의 「코드는 고치지 않는다」는 프롬프트일 뿐이라, `PreToolUse` 훅(`reviewer-write-guard.sh`)이 훅 입력의 `agent_type` 으로 리뷰어를 가려 `review/` 밖의 Write · Edit 와 파일을 바꾸는 Bash 를 exit 2 로 막는다(리더는 통과). 결과 파일 없이 완료하는 것은 `TaskCompleted` 훅이 막는다.

- Agent Teams 는 **실험 기능**이라 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 이 필요하다. Sonnet 5.5 에서는 팀원이 작업 목록 도구를 쓰도록 `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` 도 필요하다. 둘 다 이 저장소의 `.claude/settings.json` 에 이미 들어 있어 이 폴더에서 `claude` 를 열면 켜진다(토큰을 많이 쓴다).
- 녹화·시연 때는 개인 설정이 섞이지 않게 `claude --setting-sources project,local` 로 여는 것을 권장한다.
- 정답지 `docs/ANSWER_KEY.md` 는 **발표 뒤에 보기**(교육용으로 공개).
- 라이선스: MIT (`LICENSE`).

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
| `.claude/agents/` | 리뷰어 정의 3개 (`security-reviewer` · `perf-reviewer` · `test-reviewer`, 읽기 도구 + `Write` + 작업 목록·메시지 도구, sonnet) |
| `.claude/settings.json` | 팀 기능 환경변수, 허용 목록, `PreToolUse` · `TaskCompleted` 훅 |
| `.claude/hooks/reviewer-write-guard.sh` | 리뷰어(`agent_type` 이 리뷰어 셋 중 하나)가 `review/` 밖에 Write · Edit 하거나 파일을 바꾸는 Bash 를 쓰면 막는다(exit 2, 이유와 대안을 돌려줌) |
| `.claude/hooks/require-report.sh` | `review/<팀원 이름>.md` 가 비어 있으면 완료를 막는다(exit 2) |
| `review/` | 리뷰어 결과가 쌓이는 폴더 (`*.md` 는 git 무시) |
| `scripts/reset.sh` | 녹화 사이사이 초기화 |

## 녹화 순서 (요약)

1. `scripts/reset.sh` → 터미널 글자 크게, 알림 끄기, 시작 배너(계정 줄)는 편집에서 컷.
2. 편집기에 `.claude/agents/*.md` → `settings.json` → 훅 스크립트를 차례로 보여 준다.
3. 이 폴더에서 `claude` 실행(처음이면 폴더 신뢰 허용) → 아래 프롬프트 붙여 넣기.
4. 팀원이 뜨면 `Ctrl+T`로 작업 목록, 팀원을 골라 직접 메시지.
5. 훅 장면: tests 팀원에게 「결과 파일 쓰기 전에 작업부터 완료로 표시해 봐」.
   쓰기 제한 장면: security 팀원에게 「찾은 버그를 app/routes.py 에서 직접 고쳐 봐」 → 훅이 막고 안내가 뜬다.
6. 리더 요약이 나오면 `docs/ANSWER_KEY.md` 표와 대조(편집에서 옆에 붙인다).
7. 팀원 종료 → 끝나면 환경변수를 `0` 으로 되돌리고 `scripts/reset.sh`.

## 리더에게 붙여 넣을 프롬프트

```text
이 저장소를 리뷰할 팀을 만들어. 팀원 3명을 Sonnet으로 띄워(팀원 이름은 아래 영문 이름 그대로 — 결과 파일명과 훅이 이 이름을 쓴다): 이름 security 는 security-reviewer 타입, perf 는 perf-reviewer 타입, tests 는 test-reviewer 타입. 각자 자기 렌즈만 보고 review/<이름>.md 에 결과를 써. 결과를 쓴 뒤에는 다른 팀원의 review/<이름>.md 를 읽고 틀린 지적이 있으면 그 팀원에게 메시지로 직접 반박해. 시연용으로 tests 는 결과 파일을 쓰기 전에 먼저 자기 작업을 완료로 표시해 봐(훅이 막으면 그 안내대로 파일을 쓰고 다시 완료해). 리더는 직접 리뷰하지 말고 셋이 끝날 때까지 기다린 다음, 겹치는 지적을 합쳐 심각한 순서로 5줄 요약해. 끝나면 팀원 셋 다 종료시켜.
```

## 초기화

```bash
scripts/reset.sh                       # review/ 결과와 DB 지움
git status --short                     # 코드가 바뀌었으면
git reset --hard <첫 커밋>             # 첫 커밋 상태로 완전히 되돌림 (git log 로 해시 확인)
```

## 알아 둘 것

- 리뷰어는 `Edit` · `Bash` 가 없고, `Write` 는 `reviewer-write-guard.sh` 가 `review/` 안으로만 통과시킨다. 이 훅은 권한 확인보다 먼저 돌아 `--dangerously-skip-permissions` 에서도 막는다.
- 쓰기 제한 훅은 **fail-closed** 다: jq 가 없거나 입력 JSON 을 못 읽으면 쓰기 도구 호출을 막는다(리더 포함). 리뷰어 판별은 in-process 팀원 · 서브에이전트에서 확인했다(Claude Code 2.1.308).
- `permissions.deny` 로 `docs/` 읽기를 막았지만 Grep 까지 완전히 막지는 못한다. 정답지를 다른 곳에 옮겨 찍고 싶으면 `docs/` 를 저장소 밖으로 빼도 된다.
