# guide-gen

> 정책 문서 + 코드베이스 + 화면 이미지 3종 소스를 조합해 NotebookLM MCP로 배포급 가이드 슬라이드(PDF + PPTX)를 자동 생성하는 Claude Code 스킬.

## 목차

- [특징](#특징)
- [5분 빠른 시작](#5분-빠른-시작)
- [상세 설치 가이드 (Step-by-Step)](#상세-설치-가이드-step-by-step)
- [상세 사용 가이드 (Step-by-Step)](#상세-사용-가이드-step-by-step)
- [트러블슈팅](#트러블슈팅)
- [관리 · 참고](#관리--참고)

---

## 특징

- **두 가지 생성 모드**:
  - **정책·코드 모드** (이미지 업로드 없음): NotebookLM이 AI 개념 일러스트·와이어프레임을 자동 생성해 삽입
  - **화면별 상세 모드** (실제 UI 이미지 업로드): 업로드한 PNG가 슬라이드에 그대로 삽입됨
- **코드 자동 추출**: Claude Code가 도메인 키워드로 코드베이스를 스캔해 관련 파일을 자동 식별
- **배포 가능 포맷**: PDF(공유용) + PPTX(편집용) 동시 산출
- **백그라운드 생성**: 5~15분 생성 시간은 서브에이전트로 처리, 메인 대화 비블로킹
- **5가지 케이스 템플릿**: 운영 교육 · 화면별 가이드 · 고객 온보딩 · 사내 기술 공유 · CS 매뉴얼

> 💡 **이미지 처리 정확히 이해하기**: NotebookLM은 슬라이드에 **추상 일러스트·다이어그램·아이콘은 자동 생성**해서 넣습니다. 이미지 업로드 없이도 슬라이드에 비주얼이 들어갑니다. 단, 해당 제품의 **실제 UI 스크린샷은 재현하지 못합니다** — 그건 원본 PNG를 공급해야 합니다. 두 모드의 차이는 "이미지 유무"가 아니라 "AI 일러스트냐 vs 실물 UI 스크린샷이냐"입니다.

---

## 5분 빠른 시작

처음 쓰는 분은 이것만 따라하면 첫 결과물이 나옵니다.

```bash
# 1. NotebookLM CLI 설치 (한 번만)
pip install notebooklm-py
notebooklm login                    # 브라우저 OAuth 창 자동 오픈
notebooklm language set ko

# 2. guide-gen 스킬 설치 (한 번만)
git clone https://github.com/prayise/feature-guide-generator.git
cd feature-guide-generator
./install.sh

# 3. Claude Code 재시작 후 대화창에서:
# "B2M 권한시스템 운영팀 가이드 만들어줘"
#
# → 5~15분 후 projects/{서비스}/{프로젝트}/assets/{slug}-guide.pdf + .pptx 자동 생성
```

**문제 발생 시**: 아래 [트러블슈팅](#트러블슈팅) 섹션 참조.

---

## 상세 설치 가이드 (Step-by-Step)

### 전제 조건

- **OS**: macOS / Linux (Windows는 WSL 권장)
- **Python**: 3.9 이상 (`python3 --version`으로 확인)
- **Google 계정**: NotebookLM 접근 가능한 계정 필요 (무료 계정 OK)
- **Claude Code**: 설치되어 있고 동작 중

### Step 1. NotebookLM CLI 설치 및 로그인

**1-1. CLI 패키지 설치**
```bash
pip install notebooklm-py
```

설치 확인:
```bash
notebooklm --version
# → notebooklm-py 0.3.x 같은 버전 출력되면 성공
```

**1-2. 브라우저 로그인 (OAuth)**
```bash
notebooklm login
```

실행하면 자동으로 기본 브라우저가 열리면서 Google 로그인 페이지가 나옵니다. NotebookLM에 접근 가능한 Google 계정으로 로그인하고 권한을 승인하세요.

완료되면 터미널에 다음 메시지:
```
✅ Successfully authenticated as: your-email@example.com
```

**1-3. 인증 상태 확인**
```bash
notebooklm status
```
출력 예시:
```
Authenticated as: your-email@example.com
Default language: en
Current context: (none)
```

**1-4. 한국어 결과물 설정 (선택이지만 권장)**
```bash
notebooklm language set ko
```
이후 생성하는 모든 슬라이드가 한국어로 출력됩니다. 개별 호출 시 `--language ja` 같은 식으로 덮어쓸 수 있습니다.

### Step 2. guide-gen 스킬 설치

**2-1. 리포지토리 clone 후 설치 스크립트 실행**
```bash
# 원격 리포에서 clone
git clone https://github.com/prayise/feature-guide-generator.git
cd feature-guide-generator
./install.sh
```

또는 기존 프로젝트에 이미 복사되어 있는 경우:
```bash
cd /path/to/.claude/skills/guide-gen
./install.sh
```

예상 출력:
```
🔍 의존성 확인 중...
📦 guide-gen 스킬 설치 중...

✅ 설치 완료: /Users/{유저명}/.claude/skills/guide-gen

📚 설치된 파일:
   references/workflow.md
   references/prompt-template.md
   references/source-curation.md
   README.md
   SKILL.md

🚀 Claude Code에서 사용:
   "B2M 권한시스템 운영팀 가이드 만들어줘"
   또는: "/guide-gen skillflo/B2M-권한시스템"
```

**2-2. 설치 경로 확인**
```bash
ls -la ~/.claude/skills/guide-gen/
# → SKILL.md + references/ 폴더가 있으면 OK
```

**2-3. Claude Code에서 스킬 인식 확인**

Claude Code를 **재시작**한 후 대화창에 다음을 입력:
```
어떤 스킬들이 있어?
```

응답에 `guide-gen: 정책 문서 + 코드베이스 + 화면 이미지 3종 소스...`가 포함되면 설치 성공입니다.

### Step 3. (선택) 커스텀 경로 또는 제거

- 커스텀 경로 설치: `./install.sh --target /Users/.../custom/path`
- 제거: `./install.sh --uninstall`

---

## 상세 사용 가이드 (Step-by-Step)

### 사용 전 체크리스트

실제 가이드 생성을 시작하기 전에 아래를 확인하세요:

**필수**
- [ ] 프로젝트 폴더에 **정책 문서**(`*--detailed-spec.md` 또는 `*--high-level-plan.md`)가 있다
- [ ] 관련 **코드베이스**(skillflo-api/web 등)가 로컬에 clone 되어 있다
- [ ] NotebookLM CLI이 `notebooklm status`에서 Authenticated로 나온다

**선택 — 어떤 모드로 만들지 결정**
- [ ] **모드 A (정책·코드)**: 이미지 업로드 불필요. NotebookLM이 AI로 개념 일러스트를 생성해 넣어줌 (단, 실제 UI는 아님). 개념·정책 이해용으로 충분할 때
- [ ] **모드 B (실제 UI 스크린샷)**: `assets/` 또는 `mockup/` 아래 **실제 화면 PNG 5장 이상** 준비. 고객에게 실제 조작 화면을 보여줘야 할 때

> 💡 모드는 이미지 업로드 유무로 자동 결정됩니다. 모드 A여도 슬라이드에 비주얼이 들어가긴 하지만 그건 AI 생성 개념 일러스트입니다. 실물 UI가 필요하면 명시적으로 PNG를 준비하세요.

### Step 1. Claude Code 대화창에 요청 입력

다음 중 하나의 형태로 요청:

**자연어 요청**
```
"B2M 권한시스템 운영팀 가이드 만들어줘"
"진단 티켓 기능 고객 온보딩 자료 필요해"
"새 결제 모듈 사내 기술 공유 자료 만들어줘"
```

**슬래시 명령어 (구체적 옵션 지정)**
```
/guide-gen skillflo/B2M-권한시스템
/guide-gen skillmatch/diagnosis-ticket --audience "고객사 교육담당자" --purpose "셀프 온보딩"
```

### Step 2. Claude Code가 자동 수행 (약 2분)

진행 상황이 대화창에 표시됩니다:

```
🔍 프로젝트 스캔 중... → projects/skillflo/B2M-권한시스템/
📄 정책 문서 발견: sf-b2m-auth--detailed-spec.md
🖼️  화면 이미지 8장 발견: assets/*.png, mockup/*.png
🔎 코드베이스 스캔 중... (도메인 키워드: b2m, member, role, 권한)
✅ 관련 파일 6개 식별:
   - skillflo-api/src/api/b2m/member/member-handler.ts (265줄)
   - skillflo-api/src/api/b2m/member/schema.ts (384줄)
   ...
📦 NotebookLM 노트북 생성 중...
📤 15개 소스 업로드 중...
✍️  프롬프트 설계 완료, 슬라이드 생성 요청...
```

### Step 3. 백그라운드 생성 대기 (5~15분)

생성 요청 후 대화창에 다음과 같이 표시됩니다:

```
⏳ 슬라이드 생성 중 (artifact_id: abc123...)
   예상 소요: 5~15분
   메인 대화는 블로킹되지 않습니다. 다른 작업 계속 가능.
```

이 시간 동안 **Claude Code와 계속 다른 대화를 할 수 있습니다**. 백그라운드 서브에이전트가 알아서 완료 감지 + 다운로드를 처리합니다.

### Step 4. 완료 알림 확인

완료되면 대화창에 다음이 자동 출력됩니다:

```
✅ 가이드 생성 완료!

📁 projects/skillflo/B2M-권한시스템/assets/
   - sf-b2m-auth-guide.pdf   (17MB, 22장)
   - sf-b2m-auth-guide.pptx  (19MB, 편집 가능)

📊 생성 통계:
   - 사용된 소스: 15개 (정책 1 + 코드 6 + 이미지 8)
   - 생성 시간: 12분 34초
```

### Step 5. 결과물 확인 및 배포

**열어보기**
```bash
open projects/skillflo/B2M-권한시스템/assets/sf-b2m-auth-guide.pdf
open projects/skillflo/B2M-권한시스템/assets/sf-b2m-auth-guide.pptx
```

**배포 전 체크**
- PDF로 Slack/이메일 공유
- PPTX는 Keynote/PowerPoint에서 열어 회사 브랜딩·용어 조정
- 슬라이드 중 부정확한 부분이 있으면 정책 문서·이미지를 먼저 보정한 뒤 재생성

**재생성** (정책 업데이트 후)
```
"B2M 권한시스템 가이드 재생성해줘" 또는 "/guide-gen skillflo/B2M-권한시스템"
```
기존 파일이 있으면 덮어쓸지 확인 후 진행합니다.

---

## 트러블슈팅

### ❌ `notebooklm: command not found`
**원인**: CLI 설치 안 됨 또는 PATH 미설정
**해결**:
```bash
pip install --user notebooklm-py
# 또는 pipx install notebooklm-py
which notebooklm   # 경로 확인
```
경로가 나오지 않으면 Python bin 디렉토리가 PATH에 없는 것. `~/.zshrc` 또는 `~/.bashrc`에 추가:
```
export PATH="$HOME/.local/bin:$PATH"
```

### ❌ `notebooklm login` 후에도 `not authenticated`
**원인**: 쿠키 저장 실패 또는 세션 만료
**해결**:
```bash
notebooklm auth check        # 진단 정보 출력
notebooklm login             # 재로그인
```
여전히 실패하면 브라우저 쿠키 캐시 정리 후 재시도.

### ❌ 스킬 설치 후 Claude Code에 안 나타남
**원인**: Claude Code 재시작 안 됨 또는 잘못된 경로
**해결**:
1. Claude Code 완전 종료 후 재시작
2. `ls ~/.claude/skills/guide-gen/SKILL.md` 로 파일 존재 확인
3. `SKILL.md` 최상단 frontmatter(`---` 블록)가 유효한 YAML인지 확인

### ⚠️ 슬라이드 생성이 15분 넘게 걸림
**원인**: Google 레이트 리밋 또는 큰 소스 파일
**해결**:
```bash
notebooklm artifact list --notebook <notebook_id>
```
status가 `in_progress`면 추가 5~10분 대기. `failed`면 10분 후 재시도. 반복 실패 시 소스 수를 줄이고 재시도.

### ⚠️ PDF는 받았는데 PPTX 다운로드 실패
**원인**: NotebookLM이 PPTX 변환을 간헐적으로 실패
**해결**:
```bash
yes y | notebooklm download slide-deck /path/to/guide.pptx --format pptx -a <artifact_id> -n <notebook_id>
```
수동 재다운로드. Claude Code에서도 "PPTX만 다시 받아줘"로 재요청 가능.

### ⚠️ 생성된 슬라이드 내용이 부정확하거나 엉뚱함
**원인**: 소스 큐레이션 문제 (관련 없는 코드/이미지 포함)
**해결**: `references/source-curation.md` 참조. 핵심 원칙:
- 소스 10개 이내로 제한
- 정책 문서는 1~2장만 (버전 여러 개 넣지 않기)
- 이미지는 해당 기능과 직접 관련된 것만
- 실패 업로드 소스(`preparing` 상태)는 반드시 삭제

### ❌ `.ts/.tsx` 파일 업로드 실패
**원인**: NotebookLM이 TypeScript MIME 타입을 거부
**해결**: 스킬이 자동으로 마크다운 래핑을 수행하지만, 수동으로 할 경우:
```bash
echo "# filename.ts"; echo '```typescript'; cat file.ts; echo '```'
```
형태로 `.md` 파일로 저장 후 업로드.

---

## 관리 · 참고

### 파일 구조

```
.claude/skills/guide-gen/
├── SKILL.md                  # Claude Code가 읽는 스킬 정의
├── README.md                 # 이 파일
├── install.sh                # CLI 설치 스크립트
└── references/               # Progressive disclosure (필요 시 로드)
    ├── workflow.md           # 4단계 상세 실행 가이드
    ├── prompt-template.md    # 5가지 케이스별 프롬프트 템플릿
    └── source-curation.md    # 소스 큐레이션 전략과 함정 대응
```

글로벌 설치 후: `~/.claude/skills/guide-gen/`에 `SKILL.md`와 `references/`만 배치 (install.sh, README.md는 미복사).

### 실제 사용 사례

`projects/skillflo/B2M-권한시스템/`에서 이 패턴으로 생성한 결과물:

| 덱 | 모드 | 업로드 소스 | 결과물의 비주얼 |
|----|------|----------|---------------|
| 운영팀 가이드 (정책·개념 중심) | **A** | 정책 md 1 + 코드 md 6 (이미지 0) | PDF 14MB, 17장 — NotebookLM이 **AI 생성한 3D 계층 일러스트·와이어프레임**이 모든 슬라이드에 포함 (실제 Skillflo UI는 아님) |
| 화면별 상세 가이드 | **B** | 정책 md 1 + 실제 화면 PNG 8 | PDF 17MB, 22장 — **실제 Skillflo B2M 화면 스크린샷** + AI 보조 일러스트 |
| 이 스킬 자체 소개 자료 | A | 튜토리얼 md 1 | PDF 23MB, 22장 — AI 생성 일러스트 중심 |

> 💡 **중요 구분**: 첫 번째 덱에 들어있는 이미지는 NotebookLM이 **개념을 시각화한 AI 생성 일러스트**입니다 (3D 계층 렌더링, 토글-박스 다이어그램 등). 실제 Skillflo의 B2M 권한 설정 화면을 재현한 게 아닙니다. 고객이 실제로 조작하는 화면을 설명하려면 두 번째 덱처럼 실제 UI 스크린샷 PNG를 공급해야 합니다.

### 관련 스킬

- **notebooklm** — 실제 슬라이드 생성 엔진 (이 스킬의 의존성, https://github.com/teng-lin/notebooklm-py)
- **pm** — 정책 문서(`detailed-spec.md`) 생성 (이 스킬의 1차 입력)
- **design** — 화면 목업(`*.pen`) 생성 (PNG 내보내서 소스로 사용)

### 배포 (다른 동료에게 공유)

GitHub 리포를 공유:
```
https://github.com/prayise/feature-guide-generator
```

받은 사람:
```bash
git clone https://github.com/prayise/feature-guide-generator.git
cd feature-guide-generator
./install.sh
```

업데이트 받기:
```bash
cd feature-guide-generator
git pull
./install.sh      # 덮어쓰기 확인 후 재설치
```

### 라이선스

내부 사용 전용 (Day1Company B2B 교육사업 본부)
