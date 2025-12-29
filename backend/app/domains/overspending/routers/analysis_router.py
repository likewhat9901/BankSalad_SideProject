from fastapi import APIRouter, HTTPException
from app.domains.overspending.services import analyze_overspending, analyze_recurring, analyze_time_based_spending

analysis_router = APIRouter(prefix="/analysis", tags=["과소비"])

@analysis_router.get("/patterns")
def get_overspending_patterns(
    year: int | None = None,
    month: int | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
):
    """과소비 패턴 분석"""
    patterns = analyze_overspending(year=year, month=month, start_date=start_date, end_date=end_date)
    return {"count": len(patterns), "patterns": patterns}

@analysis_router.get("/recurring")
def get_recurring_patterns(
    year: int | None = None,
    month: int | None = None,
    min_count: int = 3
):
    """반복 소비 패턴 분석"""
    patterns = analyze_recurring(year=year, month=month, min_count=min_count)
    return {"count": len(patterns), "patterns": patterns}


@analysis_router.get("/time-based")
def get_time_based_patterns(
    year: int | None = None,
    month: int | None = None,
):
    """시간대 소비 분석 (충동 지점)"""
    patterns = analyze_time_based_spending(year=year, month=month)
    return {"count": len(patterns), "patterns": patterns}