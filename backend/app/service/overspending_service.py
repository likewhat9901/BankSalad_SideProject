import pandas as pd
from config import get_parquet_path
from logger import setup_logger

logger = setup_logger(__name__)

# 과소비 기준 정의 (설정만 바꾸면 됨)
OVERSPENDING_RULES = [
    {
        "name": "식사 (야간)",
        "category_filter": "식사",
        "time_filter": (18, 6),           # 야간 시간대 (18시~06시)
        "per_transaction": 10000,
    },
    {
        "name": "카페/간식",
        "category_filter": "카페/간식",
        "weekly_count": 5,
        "per_transaction": 10000,
    },
    {
        "name": "술/유흥",
        "category_filter": "술/유흥",
        "weekly_count": 3,
        "per_transaction": 30000,
    },
    {
        "name": "의복/미용",
        "category_filter": "의복/미용",
        "monthly_count": 5,
        "per_transaction": 30000,
    },
    {
        "name": "문화/여가",
        "category_filter": "문화/여가",
        "monthly_total": 10000,
        "per_transaction": 5000,
    },
]


def analyze_overspending() -> list[dict]:
    """과소비 패턴 분석"""
    parquet_path = get_parquet_path()
    
    if not parquet_path.exists():
        logger.warning("파일 없음 - 빈 결과 반환")
        return []
    
    try:
        # 1. Parquet 파일 읽기
        df = pd.read_parquet(parquet_path)

        # 2. 지출 데이터만 필터링
        df = df[df["타입"] == "지출"]
        df["금액"] = df["금액"].abs()  # 절댓값으로 변환 (양수로)
        logger.debug(f"지출 데이터: {len(df)}건")
        
        if df.empty:
            logger.warning("지출 데이터 없음")
            return []

        # 3. 날짜 데이터 확인
        if not pd.api.types.is_datetime64_any_dtype(df["거래일시"]):
            logger.error(f"거래일시 데이터 타입 오류: {df['거래일시'].dtype}")
            raise ValueError("거래일시 데이터 타입 오류 - 거래내역 parquet 파일을 확인해주세요.")
        
        # 4. 시간, 주, 월 데이터 추가
        df["hour"] = df["거래일시"].dt.hour
        df["week"] = df["거래일시"].dt.isocalendar().week
        df["month"] = df["거래일시"].dt.to_period("M")
        
        # 5. 과소비 패턴 분석
        results = []
        for rule in OVERSPENDING_RULES:
            # 각 규칙에 대해 과소비 체크
            pattern = _check_overspending(df, rule)
            if pattern:  
                # reasons가 있는 경우만 추가    
                results.append(pattern)
        
        logger.info(f"과소비 패턴 {len(results)}건 감지")
        return results
        
    except Exception as e:
        logger.error(f"과소비 분석 실패: {e}")
        raise


def _check_overspending(df: pd.DataFrame, rule: dict) -> dict | None:
    """범용 과소비 체크 함수"""
    reasons = []
    total_amount = 0

    # 1. 카테고리 필터링
    filtered_df = df[df["대분류"] == rule["category_filter"]]
    logger.debug(f"[{rule['name']}] 카테고리 필터 후: {len(filtered_df)}건")
    
    if filtered_df.empty:
        logger.debug(f"해당 카테고리 데이터 없음: {rule['category_filter']}")
        return None
    
    # 2. 시간대 필터 (선택)
    if "time_filter" in rule:
        start_hour, end_hour = rule["time_filter"]
        if start_hour > end_hour:  # 18시~6시 같은 경우
            time_mask = (filtered_df["hour"] >= start_hour) | (filtered_df["hour"] < end_hour)
            #           (hour >= 18)                        | (hour < 6)
            #           True/False 배열                     | True/False 배열
            #           → [False, True, False, True, ...]  (Boolean Series)
        else:
            time_mask = (filtered_df["hour"] >= start_hour) & (filtered_df["hour"] < end_hour)
        # 97: Boolean으로 필터링 (True인 행만 남김)
        filtered_df = filtered_df[time_mask]
    
    if filtered_df.empty:
        logger.debug(f"해당 시간대 데이터 없음: {rule.get('time_filter')}")
        return None

    total_amount = int(filtered_df["금액"].sum())
    
    # 3. 빈도 체크 (주별)
    if "weekly_count" in rule:
        # week 컬럼으로 그룹핑 후 각 그룹의 행 개수 계산
        weekly_counts = filtered_df.groupby("week").size()
        # rule["weekly_count"]=5 이상인 것만 필터
        high_freq = weekly_counts[weekly_counts >= rule["weekly_count"]]
        # weekly_counts >= 5:
        # week
        # 1    False  (3 >= 5 → False)
        # 2    True   (7 >= 5 → True)
        # 3    True   (6 >= 5 → True)
        #
        # high_freq 결과:
        # week
        # 2     7
        # 3     6

        # 과소비 주차가 1개 이상 있으면
        if len(high_freq) > 0:
            # 과소비 결과 추가
            reasons.append(_make_reason(
                "high_frequency",
                int(weekly_counts.sum()),
                f"주 {rule['weekly_count']}회 이상 ({len(high_freq)}주)"
            ))
    
    # 4. 빈도 체크 (월별)
    if "monthly_count" in rule:
        monthly_counts = filtered_df.groupby("month").size()
        high_freq = monthly_counts[monthly_counts >= rule["monthly_count"]]
        if len(high_freq) > 0:
            reasons.append(_make_reason(
                "high_frequency",
                int(monthly_counts.sum()),
                f"월 {rule['monthly_count']}회 이상 ({len(high_freq)}개월)"
            ))
    
    # 5. 월별 총액 체크
    if "monthly_total" in rule:
        monthly_total = filtered_df.groupby("month")["금액"].sum()
        high_months = monthly_total[monthly_total >= rule["monthly_total"]]
        if len(high_months) > 0:
            reasons.append(_make_reason(
                "high_monthly",
                len(filtered_df),
                f"월 총액 {rule['monthly_total']:,}원 초과 ({len(high_months)}개월)"
            ))
    
    # 6. 건당 고액 체크
    if "per_transaction" in rule:
        expensive = filtered_df[filtered_df["금액"] >= rule["per_transaction"]]
        if len(expensive) > 0:
            reasons.append(_make_reason(
                "high_amount",
                len(expensive),
                f"건당 {rule['per_transaction']:,}원 이상 ({len(expensive)}건)"
            ))

    # reasons가 없으면 None 반환
    if not reasons:
        return None
    
    return {
        "category": rule["name"],
        "total_amount": total_amount,
        "reasons": reasons
    }


def _make_reason(type_: str, count: int, message: str) -> dict:
    """reason 딕셔너리 생성"""
    return {
        "type": type_,
        "count": count,
        "message": message
    }
