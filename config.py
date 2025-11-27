from pathlib import Path

# === 프로젝트 이름 ===
PROJECT_NAME = "banksalad"

# === 루트 디렉토리 경로 ===
BASE_DIR = Path(__file__).parent
# 루트 디렉토리 검증 (프로젝트 폴더명 검증)
if BASE_DIR.name != PROJECT_NAME:
    raise RuntimeError(
        f"config.py 위치 오류!\n"
        f"  예상: .../{PROJECT_NAME}/config.py\n"
        f"  현재: {Path(__file__)}"
    )

# === 디렉토리 경로 ===
RES_DATA_DIR = BASE_DIR / "resData"
DATA_DIR = BASE_DIR / "data"
PARSE_DIR = BASE_DIR / "parse"
LOG_DIR = BASE_DIR / "logs"

# 디렉토리 검증 (존재하지 않는 경우 예외 발생)
for path in [RES_DATA_DIR, DATA_DIR, PARSE_DIR, LOG_DIR]:
    if not path.exists():
        raise RuntimeError(f"폴더 없음: {path}")

# === 전역 변수 ===

