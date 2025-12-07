from fastapi import APIRouter
from app.service.overspending_service import analyze_overspending
from fastapi import HTTPException
import calendar

analysis_router = APIRouter(prefix="/analysis", tags=["분석"])

@analysis_router.get("/overspending")
def get_overspending_analysis(
    year: int | None = None,
    month: int | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
):
    """과소비 패턴 분석"""
    try:
        if year and month:
            # 다음 달 0일 = 해당 달 마지막 날
            last_day = calendar.monthrange(year, month)[1]
            start_date = f"{year:04d}-{month:02d}-01"
            end_date = f"{year:04d}-{month:02d}-{last_day:02d}"
        patterns = analyze_overspending(start_date=start_date, end_date=end_date)
        return {"count": len(patterns), "patterns": patterns}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="과소비 분석 중 오류 발생")
