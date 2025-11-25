import pandas as pd
from pathlib import Path
from datetime import datetime

from logger import setup_logger

logger = setup_logger(__name__)

SOURCE = Path("data/가계부_데이터_저장용.parquet")
TARGET = Path("data/커피간식.parquet")

def main():
    df = pd.read_parquet(SOURCE)
    logger.info("원본 로드: rows=%d, columns=%s", len(df), list(df.columns))

    # 날짜는 그대로 datetime, 시간은 timedelta로 변환
    date_part = pd.to_datetime(df["날짜"])
    time_part = df["시간"].apply(
        lambda t: pd.to_timedelta(
            datetime.combine(datetime.min, t) - datetime.min
        )
        if pd.notna(t) else pd.NaT
    )
    df["거래일"] = date_part + time_part
    df = df.dropna(subset=["거래일"])
    df["week_id"] = df["거래일"].dt.to_period("W").apply(lambda p: p.start_time)
    logger.info("거래일 계산 후: rows=%d", len(df))

    # 1) 커피/간식만
    filtered = df[df["대분류"].isin(["카페/간식"])].copy()
    logger.info("대분류 필터 후: rows=%d", len(filtered))
    logger.info("대분류 분포: %s", filtered["대분류"].value_counts().to_dict())

    # 2) 주별 거래 횟수 계산
    weekly_counts = filtered.groupby("week_id")["week_id"].transform("count")
    logger.info("주당 최대 거래 수: %s", weekly_counts.max())

    # 3) 건당 2만 이상이거나, 같은 주에 5회 이상 나온 거래만 남기기
    result = filtered[
        (filtered["금액"].abs() >= 5000) | (weekly_counts >= 5)
    ].reset_index(drop=True)
    logger.info("최종 필터 후: rows=%d", len(result))
    logger.info("금액 분포: %s", result["금액"].describe().to_dict())

    result.to_parquet(TARGET, index=False)
    logger.info(f"{len(result)}건 저장 완료 → {TARGET}") 

if __name__ == "__main__":
    main()