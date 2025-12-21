from pathlib import Path

import pandas as pd

from logger import setup_logger
from config import get_parquet_path


logger = setup_logger(__name__) # 로깅 설정

def excel_to_parquet(
    excel_file_path: Path, 
    sheet_name: int = 1,
) -> dict:
    """엑셀 파일을 Parquet로 변환
    
    Args:
        excel_file_path: 변환할 엑셀 파일 경로
        sheet_name: 읽을 시트 번호 (기본값: 1)
    """
    logger.info(f"엑셀 파일 '{excel_file_path.name}' 변환 시작")
    output_parquet_file = get_parquet_path()
    
    try:
        df = pd.read_excel(excel_file_path, sheet_name=sheet_name)
        logger.info(f"엑셀 파일 읽기 완료: {len(df)}행 x {len(df.columns)}열")
    except Exception as e:
        logger.error(f"엑셀 파일 읽기 오류: {e}")
        raise

    # 원본 데이터 가공
    df['거래일시'] = pd.to_datetime(df['날짜'], unit='ms') + pd.to_timedelta(df['시간'].astype(str))
    other_cols = [col for col in df.columns if col not in ['거래일시', '날짜', '시간']]
    df = df[['거래일시'] + other_cols]

    # ID 컬럼 추가
    df = df.sort_values("거래일시", ascending=False).reset_index(drop=True)

    # 거꾸로 ID 부여
    df['id'] = (len(df) - 1) - df.index
    cols = ['id'] + [col for col in df.columns if col != 'id']    # ID 컬럼을 첫 번째 위치로 이동
    df = df[cols]    # 컬럼 순서 변경

    # Parquet 파일로 저장
    output_parquet_file.parent.mkdir(parents=True, exist_ok=True)

    try:
        df.to_parquet(output_parquet_file, index=False)
        file_size_mb = output_parquet_file.stat().st_size / (1024 * 1024)
        logger.info(f"Parquet 파일 저장 완료: '{output_parquet_file}' ({file_size_mb:.2f} MB)")
    except Exception as e:
        logger.error(f"Parquet 저장 오류: {e}")
        raise

    return {
        "status": "success",
        "message": f"'{excel_file_path.name}' 변환 완료",
        "output_file": str(output_parquet_file)
    }
