import pandas as pd
from logger import setup_logger
from config import DATA_DIR

logger = setup_logger(__name__)


PARQUET_PATH = DATA_DIR / "test_excel_file.parquet"

def get_transactions(limit, category, start_date, end_date):
    """거래내역 조회"""
    logger.info(f"거래내역 조회 요청 - limit: {limit}, category: {category}, start_date: {start_date}, end_date: {end_date}")
    
    try:
        df = pd.read_parquet(PARQUET_PATH)
        original_count = len(df)
        
        if category:
            df = df[df["대분류"] == category]
        if start_date:
            df = df[df["거래일시"] >= pd.to_datetime(start_date)]
        if end_date:
            df = df[df["거래일시"] <= pd.to_datetime(end_date)]
        
        filtered_count = len(df)
        df = df.sort_values("거래일시", ascending=False).head(limit)
        df["거래일시"] = df["거래일시"].dt.strftime("%Y-%m-%d %H:%M:%S")

        logger.info(f"거래내역 조회 완료 - 전체: {original_count}건, 필터 후: {filtered_count}건, 반환: {len(df)}건")
    except FileNotFoundError:
        logger.error(f"파일 없음: {PARQUET_PATH}")
        raise
    except Exception as e:
        logger.error(f"거래내역 조회 실패: {e}")
        raise
    
    return df.to_dict(orient="records")