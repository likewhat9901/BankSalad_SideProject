from fastapi import APIRouter, HTTPException

from app.service.analysis.spending_personality_service import analyze_spending_personality


personality_router = APIRouter(prefix="/personality", tags=["소비 성향"])


@personality_router.get("")
def get_spending_personality(
    year: int | None = None,
    month: int | None = None,
):
    """소비 성향 분석 (MBTI 스타일)"""
    try:
        personality = analyze_spending_personality(year=year, month=month)
        return personality
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"소비 성향 분석 중 오류 발생: {str(e)}")