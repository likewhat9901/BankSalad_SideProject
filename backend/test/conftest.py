"""
pytest 공통 설정 및 fixtures
"""
import pytest
import sys
from pathlib import Path

from config import TEST_DIR, get_parquet_path
from fastapi.testclient import TestClient
from app.main import app


# backend 폴더를 Python path에 추가
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# 테스트 샘플 파일 경로
SAMPLE_EXCEL_PATH = TEST_DIR / "resData" / "test_excel_file.xlsx"


@pytest.fixture
def client():
    """테스트용 FastAPI 클라이언트"""
    return TestClient(app)

@pytest.fixture
def sample_excel_path():
    """샘플 엑셀 파일 경로"""
    return SAMPLE_EXCEL_PATH

@pytest.fixture
def sample_transactions_df():
    """테스트용 거래내역 DataFrame (변환된 형태)"""
    import pandas as pd
    df = pd.read_excel(SAMPLE_EXCEL_PATH, sheet_name=1)
    
    # upload_service와 동일한 변환 로직
    df['거래일시'] = pd.to_datetime(df['날짜'], unit='ms') + pd.to_timedelta(df['시간'].astype(str))
    other_cols = [col for col in df.columns if col not in ['거래일시', '날짜', '시간']]
    df = df[['거래일시'] + other_cols]
    
    return df

@pytest.fixture
def cleanup_parquet():
    """테스트 후 생성된 parquet 파일 정리"""
    yield  # ← 테스트 실행
    # ↓ 테스트 끝난 후 실행 (teardown)
    parquet_file = get_parquet_path()
    if parquet_file.exists():
        parquet_file.unlink()
