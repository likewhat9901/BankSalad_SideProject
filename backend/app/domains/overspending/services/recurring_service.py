import pandas as pd
from logger import setup_logger

from app.common.utils import (
    parse_date_params,
    filter_by_date_range,
    filter_expense_only,
    validate_datetime_column,
    enrich_with_time_data,
)
from app.domains.transaction.repository import load_transactions

logger = setup_logger(__name__)


# --------------------------------
# public functions
# --------------------------------
def analyze_recurring(
    year: int | None = None,
    month: int | None = None,
    min_count: int = 3
) -> list[dict]:
    """반복 소비 패턴 분석"""
    # 데이터 로드
    df = load_transactions()
    if df.empty:
        return []
    
    # 데이터 준비 (공통 유틸 사용)
    start_date, end_date = parse_date_params(year, month)
    # 날짜 필터링
    df = filter_by_date_range(df, start_date, end_date)
    if df.empty:
        return []
    
    # 지출 데이터만 필터링
    df = filter_expense_only(df)
    if df.empty:
        return []
      
    # 거래일시 데이터 타입 검증
    validate_datetime_column(df)
    # 시간, 요일 데이터 추가
    df = enrich_with_time_data(df)
    
    # 반복 패턴 탐지
    patterns = _detect_recurring_patterns(df, min_count)
    
    logger.info(f"반복 소비 패턴 {len(patterns)}건 감지")
    return patterns


# --------------------------------
# private functions
# --------------------------------
def _detect_recurring_patterns(df: pd.DataFrame, min_count: int) -> list[dict]:
    """반복 소비 패턴 탐지
    
    기준:
    1. 동일 상호 (내용)
    2. 동일 시간대 (시간대 그룹화: 0-6, 6-12, 12-18, 18-24)
    3. 동일 요일 (선택적)
    
    Args:
        df: 분석할 DataFrame
        min_count: 최소 반복 횟수
    
    Returns:
        반복 소비 패턴 리스트
    """
    patterns = []
    
    # 시간대 그룹화
    df["time_range"] = df["hour"].apply(_get_time_range)
    
    # 그룹화 기준: 상호명 + 시간대 + 카테고리 + 결제수단
    grouping_cols = ["내용", "time_range", "대분류", "결제수단"]
    grouped = df.groupby(grouping_cols)
    
    # 그룹화된 데이터 순회
    for (merchant, time_range, category, payment_method), group in grouped:
        # 그룹화된 데이터 건수
        count = len(group)
        
        # 건수가 최소 반복 횟수 미만이면 건너뜀
        if count < min_count:
            continue
        
        # 반복 패턴 딕셔너리 생성
        pattern = _create_pattern_dict(
            group, merchant, time_range, category, payment_method, count
        )
        # 반복 패턴 리스트에 추가
        patterns.append(pattern)
    
    # 총액 기준 내림차순 정렬 (내림차순 정렬)
    patterns.sort(key=lambda x: x["total_amount"], reverse=True)
    
    return patterns


def _get_time_range(hour: int) -> str:
    """시간을 시간대 범위 문자열로 변환
    
    Args:
        hour: 시간 (0-23)
    
    Returns:
        시간대 범위 문자열 (예: "00:00-06:00")
    """
    if 0 <= hour < 6:
        return "00:00-06:00"
    elif 6 <= hour < 12:
        return "06:00-12:00"
    elif 12 <= hour < 18:
        return "12:00-18:00"
    else:
        return "18:00-24:00"


def _create_pattern_dict(
    group: pd.DataFrame,
    merchant: str,
    time_range: str,
    category: str,
    payment_method: str,
    count: int
) -> dict:
    """반복 패턴 딕셔너리 생성
    
    Args:
        group: 그룹화된 DataFrame
        merchant: 상호명
        time_range: 시간대 범위
        category: 카테고리
        payment_method: 결제수단
        count: 반복 횟수
    
    Returns:
        패턴 딕셔너리
    """
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
    
    return {
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