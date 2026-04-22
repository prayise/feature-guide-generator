#!/usr/bin/env bash
# guide-gen 스킬 글로벌 설치 스크립트
# Usage:
#   ./install.sh                     # Claude Code 글로벌 스킬 디렉토리에 설치
#   ./install.sh --uninstall         # 제거
#   ./install.sh --target <path>     # 커스텀 경로에 설치

set -euo pipefail

SKILL_NAME="guide-gen"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TARGET="$HOME/.claude/skills/$SKILL_NAME"

# -------- 옵션 파싱 --------
UNINSTALL=false
TARGET_DIR="$DEFAULT_TARGET"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,6p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# -------- 제거 모드 --------
if $UNINSTALL; then
  if [[ -d "$TARGET_DIR" ]]; then
    rm -rf "$TARGET_DIR"
    echo "✅ guide-gen 스킬을 제거했습니다: $TARGET_DIR"
  else
    echo "ℹ️  제거할 스킬이 없습니다: $TARGET_DIR"
  fi
  exit 0
fi

# -------- 의존성 확인 --------
echo "🔍 의존성 확인 중..."
MISSING_DEPS=()

if ! command -v notebooklm >/dev/null 2>&1; then
  MISSING_DEPS+=("notebooklm-py")
fi

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
  echo ""
  echo "⚠️  다음 의존성이 설치되어 있지 않습니다:"
  for dep in "${MISSING_DEPS[@]}"; do
    echo "   - $dep"
  done
  echo ""
  echo "설치 방법:"
  echo "   pip install notebooklm-py"
  echo "   notebooklm login"
  echo "   notebooklm language set ko"
  echo ""
  read -p "의존성 없이 스킬만 설치할까요? [y/N]: " -r CONTINUE
  if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "❌ 설치 중단. 의존성 설치 후 재시도하세요."
    exit 1
  fi
fi

# -------- 기존 설치 확인 --------
if [[ -d "$TARGET_DIR" ]]; then
  echo ""
  echo "ℹ️  기존 설치가 감지되었습니다: $TARGET_DIR"
  read -p "덮어쓸까요? [y/N]: " -r OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo "❌ 설치 취소."
    exit 0
  fi
  rm -rf "$TARGET_DIR"
fi

# -------- 설치 실행 --------
echo "📦 $SKILL_NAME 스킬 설치 중..."
mkdir -p "$TARGET_DIR"

# SKILL.md + README.md + references 복사 (install.sh는 제외)
cp "$SOURCE_DIR/SKILL.md" "$TARGET_DIR/SKILL.md"
cp "$SOURCE_DIR/README.md" "$TARGET_DIR/README.md"
cp -r "$SOURCE_DIR/references" "$TARGET_DIR/references"

# -------- 검증 --------
if [[ -f "$TARGET_DIR/SKILL.md" && -d "$TARGET_DIR/references" ]]; then
  echo ""
  echo "✅ 설치 완료: $TARGET_DIR"
  echo ""
  echo "📚 설치된 파일:"
  find "$TARGET_DIR" -type f | sed "s|$TARGET_DIR/|   |"
  echo ""
  echo "🚀 Claude Code에서 사용:"
  echo "   \"B2M 권한시스템 운영팀 가이드 만들어줘\""
  echo "   또는: \"/guide-gen skillflo/B2M-권한시스템\""
  echo ""
  echo "📖 문서: $TARGET_DIR/SKILL.md"
else
  echo "❌ 설치 실패. 파일이 누락되었습니다." >&2
  exit 1
fi
