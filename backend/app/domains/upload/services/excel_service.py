import pandas as pd
from pathlib import Path
from fastapi import UploadFile

from logger import setup_logger
from app.domains.upload.utils.file_validation import validate_excel_file
from app.domains.upload.repository.file_repository import (
    read_excel_file,
    save_uploaded_file,
    save_to_parquet,
)

logger = setup_logger(__name__)


# ----------------------------------------------------------------
# public functions
# ----------------------------------------------------------------
def excel_to_parquet(excel_file_path: Path, sheet_name: int = 1) -> dict:
    """엑셀 파일을 Parquet로 변환"""
    logger.info(f"엑셀 파일 '{excel_file_path.name}' 변환 시작")
    
    # 엑셀 파일 읽기 (Repository)
    df = read_excel_file(excel_file_path, sheet_name)
    
    # 데이터 가공 (비즈니스 로직)
    df = _process_transaction_data(df)
    
    # Parquet 파일로 저장 (Repository)
    output_path = save_to_parquet(df)
    
    return {
        "status": "success",
        "message": f"'{excel_file_path.name}' 변환 완료",
        "output_file": str(output_path)
    }


def process_excel_upload(file: UploadFile, content: bytes) -> dict:
    """엑셀 파일 업로드 처리 (검증 → 저장 → 변환)"""
    # 1. 검증
    validate_excel_file(file, content)
    
    # 2. 파일 저장 (Repository)
    excel_file_path = save_uploaded_file(file.filename, content)
    
    # 3. Parquet 변환
    return excel_to_parquet(excel_file_path)


# ----------------------------------------------------------------
# private functions (비즈니스 로직)
# ----------------------------------------------------------------
def _process_transaction_data(df: pd.DataFrame) -> pd.DataFrame:
    """거래 데이터 가공"""
    # 거래일시 생성
    df['거래일시'] = pd.to_datetime(df['날짜'], unit='ms') + pd.to_timedelta(df['시간'].astype(str))
    
    # 컬럼 재정렬
    other_cols = [col for col in df.columns if col not in ['거래일시', '날짜', '시간']]
    df = df[['거래일시'] + other_cols]
    
    # ID 컬럼 추가
    df = df.sort_values("거래일시", ascending=False).reset_index(drop=True)
    df['id'] = (len(df) - 1) - df.index
    
    # ID 컬럼을 첫 번째 위치로 이동
    cols = ['id'] + [col for col in df.columns if col != 'id']
    df = df[cols]
    
    return df