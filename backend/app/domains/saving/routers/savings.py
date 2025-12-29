from fastapi import APIRouter

from app.domains.saving.services import analyze_savings_opportunities


savings_router = APIRouter(prefix="/savings", tags=["절약"])

# 절약 기회 분석 (Top 3)
@savings_router.get("/opportunities")
def get_savings_opportunities(
    year: int | None = None,
    month: int | None = None,
):
    """절약 기회 분석 (Top 3)"""
    # 절약 기회 분석
    opportunities = analyze_savings_opportunities(year=year, month=month)
    return {"count": len(opportunities), "opportunities": opportunities}
