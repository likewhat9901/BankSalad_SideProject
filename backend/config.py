import os
from pathlib import Path

# === 프로젝트 이름 ===
PROJECT_NAME = "backend"

# === 루트 디렉토리 경로 ===
BASE_DIR = Path(__file__).parent

# 배포 환경 확인 (Railway 등)
IS_DEPLOYMENT = os.getenv("RAILWAY_ENVIRONMENT") is not None or os.getenv("PORT") is not None

# 루트 디렉토리 검증 (로컬 개발 환경에서만)
if not IS_DEPLOYMENT and BASE_DIR.name != PROJECT_NAME:
    raise RuntimeError(
        f"config.py 위치 오류!\n"
        f"  예상: .../{PROJECT_NAME}/config.py\n"
        f"  현재: {Path(__file__)}"
    )

# === 디렉토리 경로 ===
APP_DIR = BASE_DIR / "app"
RES_DATA_DIR = BASE_DIR / "resData"
DATA_DIR = BASE_DIR / "data"
PARSE_DIR = BASE_DIR / "parse"
LOG_DIR = BASE_DIR / "logs"
TEST_DIR = BASE_DIR / "test"

# 디렉토리 자동 생성 (배포 환경 대응)
for path in [RES_DATA_DIR, DATA_DIR, PARSE_DIR, LOG_DIR]:
    path.mkdir(parents=True, exist_ok=True)

# === 전역 변수 ===
def get_parquet_path() -> Path:
    return DATA_DIR / "transactions.parquet"