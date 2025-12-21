import pandas as pd
from config import get_parquet_path
from logger import setup_logger

logger = setup_logger(__name__)

def get_monthly_stats(year: int, month: int) -> dict:
    """월별 통계 조회"""
    parquet_path = get_parquet_path()
    
    if not parquet_path.exists():
        logger.warning(f"파일 없음: {parquet_path}")
        return _empty_response(year, month)

    df = pd.read_parquet(parquet_path)
    df['month'] = df['거래일시'].dt.to_period('M')
    monthly = df[df['month'] == f"{year}-{month:02d}"]
    
    if monthly.empty:
        return _empty_response(year, month)
    
    # 수입/지출 분리
    income_df = monthly[monthly['금액'] > 0]
    expense_df = monthly[monthly['금액'] < 0]
    
    # 각각 집계
    income_stats = income_df.groupby('대분류')['금액'].sum()
    expense_stats = expense_df.groupby('대분류')['금액'].sum().abs()  # 지출은 절댓값
    
    total_income = int(income_stats.sum()) if not income_stats.empty else 0
    total_expense = int(expense_stats.sum()) if not expense_stats.empty else 0
    
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
    if stats.empty or total == 0:
        return []
    
    return [
        {
            "category": cat,
            "amount": int(amt),
            "percentage": round(amt / total * 100, 1)
        }
        for cat, amt in stats.sort_values(ascending=False).items()  # 금액 높은 순 정렬
    ]