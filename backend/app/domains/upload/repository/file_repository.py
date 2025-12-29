import pandas as pd
from pathlib import Path
from logger import setup_logger

from config import RES_DATA_DIR, get_parquet_path

logger = setup_logger(__name__)


def read_excel_file(excel_file_path: Path, sheet_name: int = 1) -> pd.DataFrame:
    """엑셀 파일 읽기"""

    # 엑셀 파일 읽기
    df = pd.read_excel(excel_file_path, sheet_name=sheet_name)
    
    logger.info(f"엑셀 파일 읽기 완료: {len(df)}행 x {len(df.columns)}열")
    return df


def save_uploaded_file(filename: str, content: bytes) -> Path:
    """업로드된 파일 저장"""

    # 파일 저장 경로 생성
    file_path = RES_DATA_DIR / filename
    file_path.parent.mkdir(parents=True, exist_ok=True)
    
    # 파일 저장
    with open(file_path, "wb") as f:
        f.write(content)
    
    # 저장된 파일 경로 반환
    logger.info(f"파일 저장 완료: {file_path}")
    return file_path


def save_to_parquet(df: pd.DataFrame) -> Path:
    """DataFrame을 Parquet 파일로 저장"""

    # 파일 저장 경로 생성
    output_path = get_parquet_path()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Parquet 파일로 저장
    df.to_parquet(output_path, index=False)
    
    # 파일 크기 계산
    file_size_mb = output_path.stat().st_size / (1024 * 1024)
    logger.info(f"Parquet 파일 저장 완료: '{output_path}' ({file_size_mb:.2f} MB)")
    
    # 저장된 파일 경로 반환
    return output_path