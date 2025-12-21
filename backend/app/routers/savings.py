from fastapi import APIRouter, HTTPException

from app.service.analysis.savings_service import analyze_savings_opportunities


savings_router = APIRouter(prefix="/savings", tags=["절약"])

# 절약 기회 분석 (Top 3)
@savings_router.get("/opportunities")
def get_savings_opportunities(
    year: int | None = None,
    month: int | None = None,
):
    """절약 기회 분석 (Top 3)"""
    try:
        opportunities = analyze_savings_opportunities(year=year, month=month)
        return {"count": len(opportunities), "opportunities": opportunities}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"절약 분석 중 오류 발생: {str(e)}")
