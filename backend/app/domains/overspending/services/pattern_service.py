import pandas as pd
from logger import setup_logger

from app.common.utils import (
    parse_date_params,
    filter_by_date_range,
    filter_expense_only,
    validate_datetime_column,
)
from app.domains.overspending.repository import load_rules_from_file
from app.domains.transaction.repository import load_transactions

logger = setup_logger(__name__)

# --------------------------------
# public functions
# --------------------------------
def analyze_overspending(
    year: int | None = None,
    month: int | None = None,
    start_date: str | None = None,
    end_date: str | None = None
) -> list[dict]:
    """과소비 패턴 분석"""
    df = load_transactions()
    if df.empty:
        return []
    
    # 데이터 준비 (공통 유틸 사용)
    start_date, end_date = parse_date_params(year, month, start_date, end_date)
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
    # 시간, 주, 월 데이터 추가
    df = _enrich_with_analysis_data(df)
    
    # 과소비 패턴 분석
    results = _analyze_overspending_patterns(df)
    
    logger.info(f"과소비 패턴 {len(results)}건 감지")
    return results


# --------------------------------
# private functions - Data Enrichment
# --------------------------------
def _enrich_with_analysis_data(df: pd.DataFrame) -> pd.DataFrame:
    """시간, 주, 월 데이터 추가"""
    # 시간 데이터 추가
    df["hour"] = df["거래일시"].dt.hour
    # 주 데이터 추가
    df["week"] = df["거래일시"].dt.isocalendar().week
    # 월 데이터 추가
    df["month"] = df["거래일시"].dt.to_period("M")
    # 데이터프레임 반환
    return df


# --------------------------------
# private functions
# --------------------------------
def _analyze_overspending_patterns(df: pd.DataFrame) -> list[dict]:
    """과소비 패턴 분석"""
    # 과소비 규칙 조회
    rules = load_rules_from_file(include_disabled=False)
    # 과소비 패턴 리스트
    results = [
        pattern for rule in rules
        # 과소비 패턴 체크
        if (pattern := _check_overspending(df, rule)) is not None
    ]
    
    return results


def _make_reason(type_: str, count: int, message: str) -> dict:
    """reason 딕셔너리 생성"""
    return {"type": type_, "count": count, "message": message}


def _filter_by_rule(df: pd.DataFrame, rule: dict) -> pd.DataFrame:
    """규칙에 따라 데이터 필터링"""
    # 카테고리 필터링
    filtered_df = df[df["대분류"] == rule["category_filter"]]
    if filtered_df.empty:
        return filtered_df
    
    # 시간대 필터 (선택)
    if "time_filter" in rule:
        # 시간대 필터링
        start_hour, end_hour = rule["time_filter"]
        if start_hour > end_hour:
            time_mask = (filtered_df["hour"] >= start_hour) | (filtered_df["hour"] < end_hour)
        else:
            time_mask = (filtered_df["hour"] >= start_hour) & (filtered_df["hour"] < end_hour)
        # 시간대 필터링 결과 적용
        filtered_df = filtered_df[time_mask]
    
    return filtered_df


def _check_overspending(df: pd.DataFrame, rule: dict) -> dict | None:
    """범용 과소비 체크 함수"""
    # 데이터 필터링
    filtered_df = _filter_by_rule(df, rule)
    if filtered_df.empty:
        return None

    # 총액 계산
    total_amount = int(filtered_df["금액"].sum())
    # 이유 리스트
    reasons = []
    
    # 조건 체크 함수들을 딕셔너리로 관리
    checkers = {
        'weekly_count': _check_weekly_count,
        'monthly_count': _check_monthly_count,
        'monthly_total': _check_monthly_total,
        'per_transaction': _check_per_transaction,
    }
    
    # 각 조건 체크
    for key, checker in checkers.items():
        if key in rule:
            reason = checker(filtered_df, rule[key], rule.get('name', ''))
            if reason:
                reasons.append(reason)

    if not reasons:
        return None
    
    # 과소비 패턴 반환
    return {
        "category": rule["name"],
        "total_amount": total_amount,
        "reasons": reasons
    }


def _check_weekly_count(df: pd.DataFrame, threshold: int, rule_name: str) -> dict | None:
    """주별 빈도 체크"""
    # 주별 빈도 계산
    weekly_counts = df.groupby("week").size()
    
    # 주별 빈도가 있으면 주별 빈도 반환
    high_freq = weekly_counts[weekly_counts >= threshold]
    if len(high_freq) > 0:
        # 주별 빈도 반환
        return _make_reason(
            "high_frequency",
            int(weekly_counts.sum()),
            f"주 {threshold}회 이상 ({len(high_freq)}주)"
        )
    # 주별 빈도 체크 실패 반환
    return None


def _check_monthly_count(df: pd.DataFrame, threshold: int, rule_name: str) -> dict | None:
    """월별 빈도 체크"""
    # 월별 빈도 계산
    monthly_counts = df.groupby("month").size()
    # 월별 빈도가 있으면 월별 빈도 반환
    high_freq = monthly_counts[monthly_counts >= threshold]
    # 월별 빈도가 있으면 월별 빈도 반환
    if len(high_freq) > 0:
        # 월별 빈도 반환
        return _make_reason(
            "high_frequency",
            int(monthly_counts.sum()), 
            f"월 {threshold}회 이상 ({len(high_freq)}개월)"
        )
    # 월별 빈도 체크 실패 반환
    return None


def _check_monthly_total(df: pd.DataFrame, threshold: int, rule_name: str) -> dict | None:
    """월별 총액 체크"""
    # 월별 총액 계산
    monthly_total = df.groupby("month")["금액"].sum()
    # 월별 총액이 있으면 월별 총액 반환
    high_months = monthly_total[monthly_total >= threshold]
    if len(high_months) > 0:
        # 월별 총액 반환
        return _make_reason(
            "high_monthly",
            len(df),
            f"월 총액 {threshold:,}원 초과 ({len(high_months)}개월)"
        )
    # 월별 총액 체크 실패 반환
    return None


def _check_per_transaction(df: pd.DataFrame, threshold: int, rule_name: str) -> dict | None:
    """건당 고액 체크"""
    # 건당 고액 계산
    expensive = df[df["금액"] >= threshold]
    # 건당 고액이 있으면 건당 고액 반환
    if len(expensive) > 0:
        # 건당 고액 반환
        return _make_reason(
            "high_amount",
            len(expensive),
            f"건당 {threshold:,}원 이상 ({len(expensive)}건)"
        )
    # 건당 고액 체크 실패 반환
    return None