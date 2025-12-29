from fastapi import APIRouter

from app.domains.personality.services import analyze_spending_personality


personality_router = APIRouter(prefix="/personality", tags=["소비 성향"])


@personality_router.get("")
def get_spending_personality(
    year: int | None = None,
    month: int | None = None,
):
    """소비 성향 분석 (MBTI 스타일)"""
    # 소비 성향 분석
    personality = analyze_spending_personality(year=year, month=month)
    return personality