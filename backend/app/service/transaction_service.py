import pandas as pd
from config import get_parquet_path

from logger import setup_logger


logger = setup_logger(__name__)

def get_transactions(
    limit: int,
    offset: int,
    category: str | None,
    start_date: str | None,
    end_date: str | None
) -> tuple[list[dict], int]:
    """거래내역 조회"""
    parquet_path = get_parquet_path()

    logger.info(f"거래내역 조회 요청 - limit: {limit}, offset: {offset}, category: {category}, start_date: {start_date}, end_date: {end_date}")
    
    if not parquet_path.exists():
        logger.warning(f"파일 없음: {parquet_path} - 빈 배열 반환")
        return [], 0

    try:
        df = pd.read_parquet(parquet_path)
        
        if category:
            df = df[df["대분류"] == category]
        if start_date:
            df = df[df["거래일시"] >= pd.to_datetime(start_date)]
        if end_date:
            df = df[df["거래일시"] <= pd.to_datetime(end_date)]
        
        total_count = len(df)  # 필터 후 전체 개수

        # 정렬 후 offset ~ offset+limit 구간만 가져오기
        df = df.sort_values("거래일시", ascending=False).iloc[offset:offset + limit]
        df["거래일시"] = df["거래일시"].dt.strftime("%Y-%m-%d %H:%M:%S")

        logger.info(f"거래내역 조회 완료 - 전체: {total_count}건, 반환: {len(df)}건")
        return df.to_dict(orient="records"), total_count

    except Exception as e:
        logger.error(f"거래내역 조회 실패: {e}")
        raise
    