#!/usr/bin/env bash
# 과제 폴더(현재 디렉터리)에 하네스를 깐다. 이미 있는 파일은 덮어쓰지 않는다.
set -euo pipefail
H="$(cd "$(dirname "$0")" && pwd)"
mkdir -p .harness .agents/skills
cp -rn "$H/tools" .harness/ 2>/dev/null || true
cp -n "$H/intake.md" .harness/ 2>/dev/null || true
cp -n "$H/GOAL.md" .harness/ 2>/dev/null || true
cp -n "$H/roles.md" .harness/ 2>/dev/null || true
cp -rn "$H/skills/." .agents/skills/ 2>/dev/null || true
for f in PLAN NOTES SUBMISSION STATE; do
  [ -e "$f.md" ] && echo "skip $f.md (이미 있음)" || cp "$H/templates/$f.md" "$f.md"
done
if [ -e AGENTS.md ]; then
  grep -q "cofa-harness" AGENTS.md || { printf '\n\n' >> AGENTS.md; cat "$H/AGENTS.md" >> AGENTS.md; echo "AGENTS.md 뒤에 덧붙임"; }
else
  cp "$H/AGENTS.md" AGENTS.md
fi
# 상위 폴더가 이미 git 저장소면 새로 만들지 않는다(중첩 저장소는 작업 기록을 둘로 가른다)
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { git init -q && echo "git init"; }
# 작성자 정보가 없으면 커밋이 실패한다. 없을 때만 이 저장소에 임시값을 둔다
git config user.email >/dev/null || git config user.email "candidate@localhost"
git config user.name >/dev/null || git config user.name "candidate"
# STATE.md 시작 시각이 비어 있으면 설치 시각을 적는다
if grep -q '^- 시작 시각:[[:space:]]*$' STATE.md; then
  sed -i "s|^- 시작 시각:[[:space:]]*$|- 시작 시각: $(TZ=KST-9 date +%H:%M) (설치 시각. 실제 과제 시작과 다르면 고친다)|" STATE.md
fi
python3 .harness/tools/profile.py --selftest | tail -1
# 이 기계에 무엇이 있나 — 스택을 정하기 전에 본다
echo "python $(python3 -V 2>&1 | cut -d' ' -f2) · node $(node -v 2>/dev/null || echo 없음) · git root $(git rev-parse --show-toplevel)"
for m in pandas numpy flask fastapi streamlit openpyxl matplotlib pytest; do python3 -c "import $m" 2>/dev/null && printf '%s ' "$m"; done; echo "(설치된 파이썬 패키지)"
echo "다음: Codex 를 다시 열고 첫 줄에 메인 / 검증 / 이해 도우미 중 하나를 적는다. 같은 과제 폴더에서 메인을 먼저 시작한다. 역할은 .harness/roles.md, 진행은 STATE.md. /skills 로 5개가 보이는지 본다."
