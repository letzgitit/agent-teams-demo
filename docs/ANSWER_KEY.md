# 정답지 (녹화 중 화면에 띄우지 말 것 · 리뷰어는 읽지 않는다)

`.claude/settings.json` 의 `deny: Read(./docs/**)` 로 막아 뒀지만 Grep 은 완전히 막지 못한다.
녹화 직전 `git status` 로 이 파일이 저장소에 그대로인지, 리뷰어가 읽지 못하는지 확인한다.

| 렌즈 | 위치 | 심은 것 | 기대하는 지적 |
|---|---|---|---|
| 보안 | `app/routes.py` `search()` (f-string SQL) | 검색어 `q` 를 SQL 문자열에 그대로 끼움 → SQL 주입 | `?` 자리표시로 바꾼다 (`LIKE ?`, 값 `f"%{q}%"`) |
| 성능 | `app/routes.py` `list_todos()` (반복문 안 쿼리) | 할 일마다 태그를 따로 조회 → N+1 (할 일 N개면 쿼리 N+1번) | JOIN 또는 `IN (...)` 한 번으로 태그를 모아 온다 |
| 테스트/로직 | `app/routes.py` `create()` · `delete()` · `tests/` | 빈 제목·`None`·JSON 아님을 그대로 저장(`title` 칼럼도 NULL 허용). `delete()` 는 태그를 안 지워 고아 행이 남고, 삭제·빈 입력 테스트가 없음 | 입력 검증(400) + 빈 입력 경계값 테스트 + 삭제 테스트(태그 정리 포함) |

## 재현

```bash
.venv/bin/python -m pytest -q                 # 정상 테스트: 통과해야 한다
.venv/bin/python -m pytest -q docs/verify_bugs.py   # 버그 확인용: 4개가 실패해야 정상(= 버그가 살아 있음)
```

`docs/verify_bugs.py` 는 「고쳐졌다면 통과할」 기대 동작을 적은 것이다. 지금은 실패 = 버그 존재.
