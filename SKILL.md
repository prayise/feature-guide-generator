---
name: guide-gen
description: "정책 문서 + 코드베이스 + 화면 이미지 3종 소스를 자동으로 큐레이션하여 NotebookLM MCP로 배포급 가이드 슬라이드 덱(PDF + PPTX)을 생성하는 스킬. 사용 시점: (1) '/guide-gen [프로젝트명]' 명령어 호출, (2) '~ 운영팀 가이드 만들어줘', '~ 발표 자료 만들어줘', '~ 교육 자료 만들어줘' 요청 시, (3) '신기능 릴리즈 가이드', '고객사 온보딩 자료', '사내 기술 공유 자료', 'CS 매뉴얼', '정책 변경 공지 자료' 같은 배포용 슬라이드가 필요할 때, (4) 기획서·PRD 같은 정책 문서 + 실제 구현 코드 + 화면 목업이 모두 존재하는 프로젝트에서 이해관계자 설명 자료가 필요할 때. 산출물: assets/{slug}-guide.pdf + assets/{slug}-guide.pptx"
---

# guide-gen — 3종 소스 믹스 슬라이드 덱 생성 스킬

정책 문서 · 실제 구현 코드 · 화면 이미지를 교차 검증 가능한 번들로 묶어, NotebookLM MCP에 전달하고 배포급 슬라이드 덱(PDF + PPTX)을 자동 생성한다.

## 핵심 원칙

**소스 큐레이션이 결과 품질의 70%를 결정한다.** NotebookLM MCP(https://github.com/teng-lin/notebooklm-py)는 변환기일 뿐이다. 진짜 일은 (1) 어떤 소스를 조합할지, (2) 어떤 프롬프트로 지시할지다.

## 언제 이 스킬을 사용하나

| 상황 | 대표 소스 조합 |
|------|---------------|
| 신기능 릴리즈 가이드 | PRD + 구현 코드 + 목업 |
| 고객사 온보딩 자료 | SOP + API 샘플 + 화면 |
| 사내 기술 공유 | 아키텍처 문서 + 핵심 모듈 코드 |
| CS 매뉴얼 | FAQ + 에러 로그 + 화면 |
| 정책 변경 공지 | 변경 전후 정책 + 코드 diff + 화면 |

## 사전 요구사항

1. **NotebookLM CLI 설치**:
   ```bash
   pip install notebooklm-py
   notebooklm login
   notebooklm language set ko   # 한국어 산출물
   ```
2. **프로젝트 구조**: `projects/{service}/{project}/` 아래에 정책 문서(`*--detailed-spec.md` 또는 `*--high-level-plan.md`) + `assets/` 또는 `mockup/` 폴더의 화면 이미지 존재
3. **코드베이스 접근 권한**: 해당 도메인의 API/Web 레포지토리에 Grep/Glob 가능

## 워크플로우 — 4단계

자세한 단계별 실행 가이드는 `references/workflow.md` 참조.

### 1. 코드베이스에서 관련 코드 자동 추출
- 프로젝트 폴더 스캔 (기획서·목업·assets 파악)
- 해당 도메인 코드 레포에서 Grep/Glob으로 키워드 매칭
- 핵심 구현 파일 5~10개 자동 식별 (API 핸들러 + 스키마 + 뷰 컴포넌트 균형)

### 2. 3종 소스 번들 구성
- **정책 문서** (1~2장): Single source of truth
- **코드 파일** (5~10장): `.ts/.tsx`는 마크다운 래핑 필수 (NotebookLM이 거부)
- **화면 이미지** (5~15장): PNG — 기본/검색/빈 상태 등 다양한 상태

### 3. 대상자 맞춤 프롬프트 설계
프롬프트에 반드시 포함할 4요소 — (1) 대상 독자 (2) 슬라이드 목차 번호·제목 (3) 시각적 지시 (4) 문구 기준. 템플릿은 `references/prompt-template.md` 참조.

### 4. 백그라운드 생성 & 다운로드
`notebooklm generate slide-deck --json` → task_id 캡처 → 서브에이전트로 `artifact wait` + PDF·PPTX 다운로드 (메인 대화 비블로킹)

## 명령어 형태

```
/guide-gen [서비스명/프로젝트명] [--audience "대상자"] [--purpose "목적"]
```

예시:
```
/guide-gen skillflo/B2M-권한시스템 --audience "운영팀(CSM/교담자)" --purpose "4/21 릴리즈 교육"
/guide-gen skillmatch/diagnosis-ticket --audience "고객사 교육담당자" --purpose "셀프 온보딩"
```

또는 자연어 호출:
```
"B2M 권한시스템 운영팀 가이드 만들어줘"
"진단 티켓 기능 고객 온보딩 자료 필요해"
```

## 산출물

프로젝트 폴더의 `assets/` 하위에 저장:
- `{slug}-guide.pdf` — 공유 배포용 (Slack·이메일·Confluence)
- `{slug}-guide.pptx` — 편집용 (브랜딩·용어 조정)

## 주의사항

1. **.ts/.tsx 직접 업로드 금지** — NotebookLM이 400 Bad Request로 거부. 마크다운으로 래핑해서 업로드한다 (`references/workflow.md`의 "코드 래핑" 섹션 참조).
2. **실패한 소스는 즉시 정리** — `preparing` 상태로 남으면 슬라이드 품질 저하. `notebooklm source delete`로 제거.
3. **프롬프트 내 셸 특수문자 주의** — 백틱·`!`·`$` 등은 heredoc으로 이스케이프.
4. **생성 시간 5~15분** — 반드시 서브에이전트(Task tool)로 백그라운드 대기. 메인 대화 블로킹 금지.

## 다른 스킬과의 관계

- **`pm` 스킬**: `detailed-spec.md`가 이 스킬의 1차 입력. `pm`으로 정책 문서를 확정한 뒤 `guide-gen`으로 공유 자료화.
- **`design` 스킬**: `mockup/*.png` 또는 `assets/*.png`가 이 스킬의 화면 이미지 소스.
- **`research` 스킬**: 외부 자료가 필요한 가이드(트렌드 리포트 등)의 경우 `research` 결과물을 소스로 추가.

## 참고 문서 (progressive disclosure)

- `references/workflow.md` — 4단계 상세 실행 가이드 (명령어 예시 포함)
- `references/prompt-template.md` — 프롬프트 작성 템플릿 + 케이스별 예시
- `references/source-curation.md` — 소스 큐레이션 전략 + 함정 대응
