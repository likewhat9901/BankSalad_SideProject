from fastapi import APIRouter
from app.service.overspending_service import analyze_overspending
from fastapi import HTTPException

analysis_router = APIRouter(prefix="/analysis", tags=["분석"])

@analysis_router.get("/overspending")
def get_overspending_analysis():
    """과소비 패턴 분석"""
    try:
        patterns = analyze_overspending()
        return {"count": len(patterns), "patterns": patterns}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="과소비 분석 중 오류 발생")
