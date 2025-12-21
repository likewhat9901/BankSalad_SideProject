import pandas as pd
import calendar
from pathlib import Path
from config import get_parquet_path
from logger import setup_logger

logger = setup_logger(__name__)


def analyze_recurring(
    year: int | None = None,
    month: int | None = None,
    min_count: int = 3
) -> list[dict]:
    """반복 소비 패턴 분석
    
    Args:
        year: 연도 (선택)
        month: 월 (선택)
        min_count: 최소 반복 횟수 (기본값: 3)
    
    Returns:
        반복 소비 패턴 리스트
    """
    parquet_path = get_parquet_path()
    
    if not parquet_path.exists():
        logger.warning("parquet 파일 없음 - 빈 결과 반환")
        return []
    
    try:
        # 데이터 로드
        df = pd.read_parquet(parquet_path)
        
        # 날짜 필터링
        if year and month:
            last_day = calendar.monthrange(year, month)[1]
            start_date = pd.Timestamp(f"{year:04d}-{month:02d}-01")
            end_date = pd.Timestamp(f"{year:04d}-{month:02d}-{last_day:02d}")
            df = df[(df["거래일시"] >= start_date) & (df["거래일시"] <= end_date)]
        
        if df.empty:
            return []
        
        # 지출 데이터만 필터링
        df = df[df["타입"] == "지출"].copy()
        df["금액"] = df["금액"].abs()
        
        if df.empty:
            return []
        
        # 날짜 데이터 타입 확인
        if not pd.api.types.is_datetime64_any_dtype(df["거래일시"]):
            raise ValueError("거래일시 데이터 타입 오류")
        
        # 시간, 요일 데이터 추가
        df["hour"] = df["거래일시"].dt.hour
        df["day_of_week"] = df["거래일시"].dt.day_name()  # Monday, Tuesday, ...
        df["date"] = df["거래일시"].dt.date
        
        # 반복 소비 패턴 탐지
        patterns = _detect_recurring_patterns(df, min_count)
        
        logger.info(f"반복 소비 패턴 {len(patterns)}건 감지")
        return patterns
        
    except Exception as e:
        logger.error(f"반복 소비 분석 실패: {e}")
        raise


def _detect_recurring_patterns(df: pd.DataFrame, min_count: int) -> list[dict]:
    """반복 소비 패턴 탐지
    
    기준:
    1. 동일 상호 (내용)
    2. 동일 시간대 (시간대 그룹화: 0-6, 6-12, 12-18, 18-24)
    3. 동일 요일 (선택적)
    """
    patterns = []
    
    # 시간대 그룹화 함수
    def get_time_range(hour: int) -> str:
        if 0 <= hour < 6:
            return "00:00-06:00"
        elif 6 <= hour < 12:
            return "06:00-12:00"
        elif 12 <= hour < 18:
            return "12:00-18:00"
        else:
            return "18:00-24:00"
    
    df["time_range"] = df["hour"].apply(get_time_range)
    
    # 그룹화 기준: 상호명 + 시간대 + 카테고리 + 결제수단
    grouping_cols = ["내용", "time_range", "대분류", "결제수단"]
    
    grouped = df.groupby(grouping_cols)
    
    for (merchant, time_range, category, payment_method), group in grouped:
        count = len(group)
        
        if count < min_count:
            continue
        
        amounts = group["금액"].tolist()
        dates = group["거래일시"].dt.date.tolist()
        
        # 날짜 정렬
        sorted_dates = sorted(dates)
        first_date = sorted_dates[0]
        last_date = sorted_dates[-1]
        
        # 요일 확인 (모두 같은 요일인지)
        day_of_week = None
        days = group["day_of_week"].unique()
        if len(days) == 1:
            day_of_week = days[0]
        
        # 패턴 키 생성
        pattern_key = f"{merchant}_{time_range}_{category}_{payment_method}"
        
        # 평균 금액 계산
        average_amount = int(sum(amounts) / len(amounts))
        total_amount = int(sum(amounts))
        
        # 주기 계산 (일 단위)
        period_days = 0
        if count > 1:
            days_diff = (last_date - first_date).days
            period_days = days_diff // (count - 1) if count > 1 else 0
        
        pattern = {
            "key": pattern_key,
            "merchant": merchant,
            "time_range": time_range,
            "day_of_week": day_of_week,
            "category": category,
            "payment_method": payment_method,
            "count": count,
            "total_amount": total_amount,
            "average_amount": average_amount,
            "first_date": first_date.isoformat(),
            "last_date": last_date.isoformat(),
            "period_days": period_days,
            "amounts": amounts,
        }
        
        patterns.append(pattern)
    
    # 총액 기준 내림차순 정렬
    patterns.sort(key=lambda x: x["total_amount"], reverse=True)
    
    return patterns