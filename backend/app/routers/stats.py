from fastapi import APIRouter, Query

from app.service.stats_service import get_monthly_stats

stats_router = APIRouter(prefix="/stats", tags=["통계"])


@stats_router.get("/monthly")
def monthly_stats(
    year: int = Query(..., description="조회할 연도", examples=[2024]),
    month: int = Query(..., ge=1, le=12, description="조회할 월 (1~12)", examples=[12])
):
    """월별 통계 조회"""
    return get_monthly_stats(year, month)