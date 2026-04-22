# guide-gen 워크플로우 상세 실행 가이드

## 단계 0: 사전 체크

```bash
# NotebookLM CLI 확인
notebooklm status
# → Authenticated as: ...@... 확인

# 언어 확인
notebooklm language get
# → ko (한국어)
```

미설정 시:
```bash
pip install notebooklm-py
notebooklm login
notebooklm language set ko
```

## 단계 1: 프로젝트 스캔 & 코드 추출

### 1-1. 프로젝트 폴더 확인

```bash
PROJECT_DIR="projects/{service}/{project}"
ls "$PROJECT_DIR"
# 찾을 것:
# - {slug}--detailed-spec.md (또는 --high-level-plan.md)
# - assets/ 또는 mockup/ 아래 PNG
# - {slug}--context.md (도메인 키워드 파악용)
```

### 1-2. 도메인 키워드 추출

`{slug}--context.md`의 "프로젝트 한 줄 요약" 섹션과 "핵심 의사결정" 테이블에서 키워드를 뽑는다. 예:
- B2M 권한시스템 → `b2m`, `member`, `role`, `permission`, `권한`
- 진단 티켓 → `diagnosis`, `ticket`, `skill`
- 강의후기 게시판 → `course-review`, `board`, `comment`

### 1-3. 코드베이스 Grep/Glob

```bash
# API 레포 (TypeORM/NestJS 계열)
find <api-repo>/src -path "*{keyword1}*" -o -path "*{keyword2}*" | grep -E '\.(ts)$' | head -10

# Web 레포 (React)
find <web-repo>/src -path "*{keyword}*" | grep -E '\.(tsx?)$' | head -10
```

**균형 원칙** — API 핸들러 2~3개 + 스키마 1~2개 + Web 뷰 2~3개 = 5~10개가 적당. 너무 많으면 NotebookLM 색인 속도 저하.

### 1-4. 코드 파일 마크다운 래핑 (필수)

NotebookLM은 `.ts/.tsx` MIME 타입을 거부한다. 반드시 마크다운으로 래핑:

```bash
mkdir -p /tmp/guide-gen-sources
cd /tmp/guide-gen-sources

for f in <list-of-code-files>; do
  base=$(basename "${f%.*}")
  ext="${f##*.}"
  {
    echo "# $(basename "$f")"
    echo
    echo "> 경로: $f"
    echo
    echo "\`\`\`${ext}"
    cat "$f"
    echo "\`\`\`"
  } > "code-${base}.md"
done
```

## 단계 2: 3종 소스 번들 구성

### 2-1. 정책 문서 복사

```bash
cp "$PROJECT_DIR/{slug}--detailed-spec.md" /tmp/guide-gen-sources/01-policy.md
```

### 2-2. 화면 이미지 선별

`assets/` 또는 `mockup/` 폴더에서 발표 흐름에 맞는 이미지만 선별 (보통 5~15장). 같은 화면의 상태별 버전(기본·검색·빈 상태)을 모두 넣으면 빈 상태 처리 설명이 정확해진다.

```bash
cp "$PROJECT_DIR/assets/"{필요한_이미지_이름}.png /tmp/guide-gen-sources/
cp "$PROJECT_DIR/mockup/"{필요한_이미지_이름}.png /tmp/guide-gen-sources/
```

### 2-3. NotebookLM 노트북 생성

```bash
notebooklm create "{프로젝트명} 가이드" --json
# → {"notebook": {"id": "..."}}
# NBID 저장
```

### 2-4. 소스 일괄 업로드

```bash
NBID=<notebook_id>
cd /tmp/guide-gen-sources

# 정책 md, 코드 md, PNG 모두 업로드
for f in *.md *.png; do
  echo "=== Adding $f ==="
  notebooklm source add "./$f" --notebook "$NBID" --json | head -5
done

# 상태 확인 — 모두 ready가 될 때까지 대기
sleep 5
notebooklm source list --notebook "$NBID"
```

### 2-5. 실패한 소스 정리

```bash
# preparing 상태로 남은 소스는 즉시 삭제
yes y | notebooklm source delete <failed_id> --notebook "$NBID"
```

## 단계 3: 프롬프트 설계

**4요소 체크리스트**:
- [ ] 대상 독자 (역할 + 기술 수준)
- [ ] 슬라이드 목차 (번호 + 제목으로 명시)
- [ ] 각 슬라이드에 쓸 이미지 파일명 언급
- [ ] 작성 원칙 (용어 기준 / TIP 박스 / 스타일 / 분량)

템플릿 상세는 `prompt-template.md` 참조.

### 3-1. 프롬프트를 heredoc으로 전달 (셸 이스케이프 회피)

```bash
PROMPT=$(cat <<'EOF'
대상: [대상자]
목적: [목적]

슬라이드 구성:
1. 표지
2. ...
22. Q&A

작성 원칙:
- ...
EOF
)

notebooklm generate slide-deck \
  --notebook "$NBID" \
  --format detailed \
  --length default \
  --language ko \
  --json \
  "$PROMPT"
# → {"task_id": "...", "status": "pending"}
# ARTIFACT_ID 저장
```

## 단계 4: 백그라운드 대기 & 다운로드

생성은 5~15분 걸린다. 메인 대화에서 `artifact wait`를 직접 호출하면 블로킹되므로, **Claude Code Task tool로 서브에이전트 스폰**.

### 4-1. 서브에이전트 프롬프트 템플릿

```
NotebookLM 슬라이드 덱 완료 대기 후 PDF + PPTX 다운로드.

파라미터:
- notebook ID: {NBID}
- artifact ID: {AID}
- 출력 경로:
  - PDF: {PROJECT_DIR}/assets/{slug}-guide.pdf
  - PPTX: {PROJECT_DIR}/assets/{slug}-guide.pptx

실행:
1. notebooklm artifact wait {AID} -n {NBID} --timeout 900
2. yes y | notebooklm download slide-deck "{PDF_PATH}" -a {AID} -n {NBID}
3. yes y | notebooklm download slide-deck "{PPTX_PATH}" --format pptx -a {AID} -n {NBID}
4. ls -lh 로 두 파일 확인 후 200자 이내 보고

exit code 대응:
- 0: 다운로드 진행
- 1: artifact list 상태 확인 후 실패 보고
- 2: 타임아웃 → 1회 재시도
```

### 4-2. 다운로드 시 덮어쓰기 옵션

기존 파일이 있으면 `--force` 또는 `yes y |` 파이프로 덮어쓰기 확인 응답.

## 단계 5: 결과 검증

```bash
ls -lh "$PROJECT_DIR/assets/{slug}-guide."{pdf,pptx}
```

확인 항목:
- PDF 크기가 10MB 이상 (빈 덱이 아닌지)
- PPTX 다운로드 성공 (편집 포맷)
- 슬라이드 수가 요청한 목차와 일치하는지 (첫 몇 장만 열어봐도 판단 가능)

## 에러 대응 빠른 참조

| 증상 | 원인 | 해결 |
|------|------|------|
| `400 Bad Request` (업로드 중) | `.ts/.tsx` 직접 업로드 | `.md` 래핑 |
| 소스가 `preparing`에서 멈춤 | 업로드 실패 잔여물 | `source delete` |
| `(eval): command not found:` | 셸 백틱·특수문자 | heredoc `<<'EOF'` |
| `artifact wait` exit 2 | 타임아웃 (드물게 15분 초과) | 재시도 또는 `artifact list` 수동 확인 |
| 다운로드 프롬프트 멈춤 | y/N 대기 | `yes y \|` 또는 `--force` |
| `GENERATION_FAILED` | Google 레이트 리밋 | 5~10분 대기 후 재시도 |
