#!/bin/bash
# PreToolUse 훅: 리뷰어(security-reviewer · perf-reviewer · test-reviewer)는 review/ 안에만 쓸 수 있다.
# 누가 도구를 불렀는지는 훅 입력의 agent_type 으로 안다. 서브에이전트와 in-process 팀원의 도구 호출에
# 들어오고, 리더(메인 세션)의 호출에는 없다 → https://code.claude.com/docs/en/hooks#common-input-fields
# exit 0 = 통과, exit 2 = 도구 호출 막기 + stderr 가 그 에이전트에게 전달된다.
# 훅이 입력을 못 읽으면(jq 없음 · JSON 깨짐) 쓰기 도구는 막는다(fail-closed).

deny() {
  echo "막힘: $1" >&2
  echo "리뷰어는 review/ 에만 쓸 수 있습니다. 코드는 고치지 말고, 고칠 점은 review/<내 팀원 이름>.md 에 '파일:줄 · 문제 · 왜 · 고칠 방향' 으로 적으세요." >&2
  exit 2
}

command -v jq >/dev/null || { echo "막힘: 쓰기 제한 훅이 jq 를 찾지 못했다(brew install jq). 훅이 확인을 못 하면 쓰기를 막는다." >&2; exit 2; }
input=$(cat)
echo "$input" | jq -e . >/dev/null 2>&1 || { echo "막힘: 쓰기 제한 훅이 입력 JSON 을 읽지 못했다. 훅이 확인을 못 하면 쓰기를 막는다." >&2; exit 2; }

agent=$(echo "$input" | jq -r '.agent_type // empty')
case "$agent" in
  security-reviewer|perf-reviewer|test-reviewer) ;;
  *) exit 0 ;;                                   # 리더와 그 밖의 에이전트는 통과
esac

tool=$(echo "$input" | jq -r '.tool_name // empty')
dir="${CLAUDE_PROJECT_DIR:-$(echo "$input" | jq -r '.cwd // empty')}"
cwd=$(echo "$input" | jq -r '.cwd // empty'); [ -z "$cwd" ] && cwd="$dir"

case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
    [ -z "$path" ] && deny "$tool 대상 경로를 알 수 없다"
    case "$path" in /*) abs="$path" ;; *) abs="$cwd/$path" ;; esac
    shown="${abs#"$dir"/}"                         # 화면에는 저장소 기준 경로만 보인다
    case "/$abs/" in */../*|*/./*) deny "경로에 . 나 .. 를 쓸 수 없다 ($shown)" ;; esac
    case "$abs" in
      "$dir"/review/?*) exit 0 ;;
      *) deny "$agent 가 review/ 밖의 파일에 $tool 하려 했다 ($shown)" ;;
    esac
    ;;
  Bash)
    # 리뷰어 정의에는 Bash 가 없다(tools 목록). 그래도 들어오면 파일을 바꾸는 명령은 막는다.
    cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
    if echo "$cmd" | grep -Eq '(^|[^0-9&<])>|>>|(^|[;&|[:space:]])(tee|mv|cp|rm|rmdir|touch|mkdir|ln|chmod|chown|truncate|dd|install|patch)([[:space:]]|$)|sed[[:space:]].*-i|perl[[:space:]].*-[a-zA-Z]*i|git[[:space:]]+(checkout|restore|reset|apply|commit|stash|clean|rm|mv)|(python[0-9.]*|node|ruby)[[:space:]]+-[ce]'; then
      deny "$agent 가 파일을 바꿀 수 있는 셸 명령을 실행하려 했다: $cmd"
    fi
    exit 0
    ;;
esac
exit 0
