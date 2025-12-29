import pandas as pd

from logger import setup_logger
from app.domains.transaction.repository import load_transactions

logger = setup_logger(__name__)

def get_monthly_stats(year: int, month: int) -> dict:
    """월별 통계 조회"""
    # 거래내역 조회
    df = load_transactions()  # repository 함수 사용
    
    # 거래내역이 없으면 빈 응답 반환
    if df.empty:
        return _empty_response(year, month)

    # 월별 거래내역 조회
    df['month'] = df['거래일시'].dt.to_period('M')
    monthly = df[df['month'] == f"{year}-{month:02d}"]
    
    # 월별 거래내역이 없으면 빈 응답 반환
    if monthly.empty:
        return _empty_response(year, month)
    
    # 수입/지출 분리 (금액이 양수이면 수입, 음수이면 지출)
    income_df = monthly[monthly['금액'] > 0]
    expense_df = monthly[monthly['금액'] < 0]
    
    # 각각 집계 (카테고리별 금액 합계)
    income_stats = income_df.groupby('대분류')['금액'].sum()
    expense_stats = expense_df.groupby('대분류')['금액'].sum().abs()  # 지출은 절댓값으로 집계
    
    # 수입/지출 총합
    total_income = int(income_stats.sum()) if not income_stats.empty else 0
    total_expense = int(expense_stats.sum()) if not expense_stats.empty else 0
    
    # 응답 생성
    return {
        "month": f"{year}-{month:02d}",
        "total_income": total_income,
        "total_expense": total_expense,
        "balance": total_income - total_expense,
        "income_count": len(income_df),
        "expense_count": len(expense_df),
        "income_breakdown": _build_breakdown(income_stats, total_income),
        "expense_breakdown": _build_breakdown(expense_stats, total_expense),
    }

def _empty_response(year: int, month: int) -> dict:
    """빈 응답 생성"""
    return {
        "month": f"{year}-{month:02d}",
        "total_income": 0,
        "total_expense": 0,
        "balance": 0,
        "income_count": 0,
        "expense_count": 0,
        "income_breakdown": [],
        "expense_breakdown": [],
    }

def _build_breakdown(stats: pd.Series, total: int) -> list:
    """카테고리별 breakdown 생성"""
    # 카테고리별 금액 합계가 없거나 총합이 0이면 빈 리스트 반환
    if stats.empty or total == 0:
        return []
    
    # 카테고리별 금액 합계 리스트 생성
    return [
        {
            "category": cat,
            "amount": int(amt),
            "percentage": round(amt / total * 100, 1)
        }
        for cat, amt in stats.sort_values(ascending=False).items()  # 금액 높은 순 정렬
    ]