import pandas as pd

from logger import setup_logger
from app.common.utils import (
    parse_date_params,
    filter_by_date_range,
    filter_expense_only,
)
from app.domains.overspending.services import (
    analyze_recurring,
    analyze_overspending,
)
from app.domains.transaction.repository import load_transactions

logger = setup_logger(__name__)


# ----------------------------------------------------------------
# public functions
# ----------------------------------------------------------------
def analyze_savings_opportunities(
    year: int | None = None,
    month: int | None = None,
) -> list[dict]:
    """절약 기회 분석 (Top 3)"""
    # 거래내역 조회
    df = load_transactions()
    # 거래내역이 없으면 빈 리스트 반환
    if df.empty:
        return []
    
    # 날짜 파라미터 파싱
    start_date, end_date = parse_date_params(year, month)
    
    # 절약 기회 리스트 초기화
    opportunities = []
    
    # 1. 반복 소비 패턴 기반 절약 기회
    opportunities.extend(_analyze_recurring_savings(year, month))
    
    # 2. 과소비 패턴 기반 절약 기회
    opportunities.extend(_analyze_overspending_savings(start_date, end_date))
    
    # 3. 카테고리별 초과 지출 기반 절약 기회 (df 전달)
    opportunities.extend(_analyze_category_savings(df, start_date, end_date))
    
    # 절약 가능 금액 기준 내림차순 정렬 후 Top 3
    opportunities.sort(key=lambda x: x["savings_amount"], reverse=True)
    top3 = opportunities[:3]
    
    logger.info(f"절약 기회 {len(top3)}건 추천")
    return top3


# ----------------------------------------------------------------
# private functions
# ----------------------------------------------------------------
def _analyze_recurring_savings(year: int | None, month: int | None) -> list[dict]:
    """반복 소비 패턴 기반 절약 기회"""
    # 반복 소비 패턴 분석
    opportunities = []
    patterns = analyze_recurring(year=year, month=month, min_count=3)
    
    # 반복 소비 패턴에서 절약 기회 생성
    for pattern in patterns:
        opportunity = _create_recurring_opportunity(pattern)
        if opportunity:
            opportunities.append(opportunity)
    
    return opportunities


def _create_recurring_opportunity(pattern: dict) -> dict | None:
    """반복 소비 패턴에서 절약 기회 생성"""
    # 반복 소비 패턴 거래 횟수
    count = pattern["count"]
    # 반복 소비 패턴 평균 금액
    average_amount = pattern["average_amount"]
    
    # 반복 소비 패턴 거래 횟수가 4회 미만이면 절약 기회 생성 안 함
    if count < 4:  # 월 4회 미만은 제외
        return None
    
    # 추천 거래 횟수 계산
    recommended_frequency = max(2, count // 2)
    savings_amount = average_amount * (count - recommended_frequency)
    
    # 절약 가능 금액이 1만원 이하면 절약 기회 생성 안 함
    if savings_amount <= 10000:  # 1만원 이하 제외
        return None
    
    # 절약 기회 생성
    return {
        "type": "recurring",
        "title": f"{pattern['merchant']} 반복 소비 줄이기",
        "description": f"월 {count}회 → 월 {recommended_frequency}회로 줄이면",
        "current_amount": pattern["total_amount"],
        "savings_amount": int(savings_amount),
        "category": pattern["category"],
        "merchant": pattern["merchant"],
        "current_frequency": count,
        "recommended_frequency": recommended_frequency,
    }


def _analyze_overspending_savings(
    start_date: str | None, 
    end_date: str | None
) -> list[dict]:
    """과소비 패턴 기반 절약 기회"""
    opportunities = []
    # 과소비 패턴 분석
    patterns = analyze_overspending(start_date=start_date, end_date=end_date)
    # 과소비 패턴에서 절약 기회 생성
    
    for pattern in patterns:
        opportunity = _create_overspending_opportunity(pattern)
        # 절약 기회가 있으면 리스트에 추가
        if opportunity:
            opportunities.append(opportunity)
    
    # 절약 기회 리스트 반환
    return opportunities


def _create_overspending_opportunity(pattern: dict) -> dict | None:
    """과소비 패턴에서 절약 기회 생성"""
    # 과소비 패턴 금액
    total_amount = pattern["total_amount"]
    savings_amount = int(total_amount * 0.3)
    
    # 절약 가능 금액이 1만원 이하면 절약 기회 생성 안 함
    if savings_amount <= 10000:
        return None
    
    # 절약 기회 생성
    return {
        "type": "overspending",
        "title": f"{pattern['category']} 과소비 줄이기",
        "description": "과소비 규칙을 지키면",
        "current_amount": total_amount,
        "savings_amount": savings_amount,
        "category": pattern["category"],
        "reasons": pattern["reasons"],
    }


def _analyze_category_savings(
    df: pd.DataFrame,
    start_date: str | None,
    end_date: str | None
) -> list[dict]:
    """카테고리별 초과 지출 기반 절약 기회"""
    # 지출 데이터만 필터링
    df = filter_by_date_range(df, start_date, end_date)
    # 필터링된 DataFrame이 없으면 빈 리스트 반환
    if df.empty:
        return []
    df = filter_expense_only(df)
    
    # 카테고리별 통계 계산
    category_stats = _calculate_category_stats(df)
    # 전체 평균 금액
    overall_avg = df["금액"].mean()
    
    opportunities = []
    # 카테고리별 절약 기회 생성
    for _, row in category_stats.iterrows():
        opportunity = _create_category_opportunity(row, overall_avg)
        if opportunity:
            opportunities.append(opportunity)
    
    return opportunities


def _calculate_category_stats(df: pd.DataFrame) -> pd.DataFrame:
    """카테고리별 통계 계산"""
    # 카테고리별 통계 계산
    stats = df.groupby("대분류").agg({
        "금액": ["sum", "mean", "count"]
    }).reset_index()
    # 카테고리별 통계 컬럼 이름 변경
    stats.columns = ["category", "total", "average", "count"]
    return stats


def _create_category_opportunity(row: pd.Series, overall_avg: float) -> dict | None:
    """카테고리 통계에서 절약 기회 생성"""
    # 카테고리 평균 금액
    category_avg = row["average"]
    # 카테고리 거래 횟수
    count = int(row["count"])
    
    # 카테고리 평균이 전체 평균보다 1.5배 이상 & 3회 이상
    if category_avg <= overall_avg * 1.5 or count < 3:
        return None
    
    # 초과 지출 금액 계산
    excess_amount = (category_avg - overall_avg) * count
    savings_amount = int(excess_amount * 0.2)
    
    # 초과 지출 금액이 1만원 이하면 절약 기회 생성 안 함
    if savings_amount <= 10000:
        return None
    
    return {
        "type": "category",
        "title": f"{row['category']} 지출 줄이기",
        "description": "평균 거래액을 줄이면",
        "current_amount": int(row["total"]),
        "savings_amount": savings_amount,
        "category": row["category"],
        "current_avg": int(category_avg),
        "recommended_avg": int(overall_avg),
    }