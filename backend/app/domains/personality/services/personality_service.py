import pandas as pd
from logger import setup_logger

from app.domains.overspending.services import (
    analyze_recurring,
    analyze_overspending,
    analyze_time_based_spending,
)
from app.domains.saving.services import analyze_savings_opportunities
from app.domains.personality.repository import (
    load_expense_transactions,
    get_personality_info,
    get_default_personality,
)
from app.common.utils import parse_date_params

logger = setup_logger(__name__)


def analyze_spending_personality(
    year: int | None = None,
    month: int | None = None,
) -> dict:
    """소비 성향 분석 (MBTI 스타일)
    
    Args:
        year: 연도 (선택)
        month: 월 (선택)
    
    Returns:
        소비 성향 정보 딕셔너리
    """
    try:
        # 거래 데이터 로드 (Repository 사용)
        df = load_expense_transactions(year, month)
        
        # 거래 데이터가 없으면 기본 유형 반환
        if df.empty:
            logger.warning("거래 데이터 없음 - 기본 유형 반환")
            return _build_personality_response(get_default_personality())
        
        # 기존 분석 데이터 수집
        recurring_patterns = analyze_recurring(year=year, month=month, min_count=3)
        
        # 날짜 파라미터 파싱
        start_date, end_date = parse_date_params(year, month, None, None)
        
        # 과소비 패턴 분석
        overspending_patterns = analyze_overspending(
            start_date=start_date, end_date=end_date
        )
        # 시간대별 소비 패턴 분석
        time_patterns = analyze_time_based_spending(year=year, month=month)
        # 절약 기회 분석
        savings_opportunities = analyze_savings_opportunities(year=year, month=month)
        
        # 거래 건수
        total_transactions = len(df)
        
        # 각 차원별 점수 계산
        scores = _calculate_all_scores(
            recurring_patterns,
            overspending_patterns,
            time_patterns,
            savings_opportunities,
            df,
            total_transactions
        )
        
        # 유형 결정
        personality_type = _determine_type(
            scores["planning"],
            scores["regular"],
            scores["recurring"],
            scores["saving"]
        )
        
        # 유형별 정보 가져오기 (Repository 사용)
        personality_info = get_personality_info(personality_type)
        
        # 응답 구성
        result = _build_personality_response(personality_info, personality_type, scores)
        
        logger.info(f"소비 성향 분석 완료: {personality_type} ({personality_info['name']})")
        return result
        
    except Exception as e:
        logger.error(f"소비 성향 분석 실패: {e}", exc_info=True)
        return _build_personality_response(get_default_personality())


# --------------------------------
# private functions - Score Calculation
# --------------------------------
def _calculate_all_scores(
    recurring_patterns: list,
    overspending_patterns: list,
    time_patterns: list,
    savings_opportunities: list,
    df: pd.DataFrame,
    total_transactions: int
) -> dict:
    """모든 차원별 점수 계산"""
    return {
        "planning": _calculate_planning_score(
            recurring_patterns, overspending_patterns, total_transactions
        ),
        "regular": _calculate_regular_score(time_patterns, df),
        "recurring": _calculate_recurring_score(recurring_patterns, total_transactions),
        "saving": _calculate_saving_score(savings_opportunities, df),
    }


def _calculate_planning_score(
    recurring_patterns: list,
    overspending_patterns: list,
    total_transactions: int
) -> float:
    """계획성 점수 계산
    - 반복 패턴이 많고, 과소비가 적을수록 계획적
    """
    if total_transactions == 0:
        return 0.5
    
    recurring_count = len(recurring_patterns)
    overspending_count = len(overspending_patterns)
    
    # 반복 패턴 비율 (높을수록 계획적)
    recurring_ratio = min(1.0, recurring_count / max(total_transactions * 0.1, 1))
    
    # 과소비 비율 (낮을수록 계획적)
    overspending_ratio = min(1.0, overspending_count / max(total_transactions * 0.1, 1))
    
    # 점수 계산: 반복 패턴 많고, 과소비 적으면 높음
    score = (recurring_ratio * 0.6) + ((1 - overspending_ratio) * 0.4)
    return max(0.0, min(1.0, score))


def _calculate_regular_score(time_patterns: list, df: pd.DataFrame) -> float:
    """규칙성 점수 계산
    - 특정 시간대에 집중되면 규칙적
    """
    logger.info(f"규칙성 계산 시작: df.empty={df.empty}, time_patterns={len(time_patterns)}")
    
    if df.empty or len(time_patterns) == 0:
        logger.warning("규칙성: df.empty 또는 time_patterns 비어있음 → 0.5 반환")
        return 0.5
    
    if "hour" not in df.columns:
        df["hour"] = df["거래일시"].dt.hour
    
    # 각 거래의 시간대를 기준으로 분산 계산
    hour_variance = df["hour"].std()
    logger.info(f"규칙성: hour_variance={hour_variance}")
    
    if pd.isna(hour_variance) or hour_variance == 0:
        # 모든 거래가 같은 시간대 → 매우 규칙적
        logger.info("규칙성: 모든 거래가 같은 시간대 → 1.0 반환")
        return 1.0
    
    # 시간대 분산의 최대값
    max_variance = 12.0
    
    # 분산이 낮을수록 (집중될수록) 규칙적
    normalized_variance = min(1.0, hour_variance / max_variance)
    score = 1.0 - (normalized_variance ** 0.7)
    
    logger.info(f"규칙성: normalized_variance={normalized_variance}, 최종 점수={score}")
    
    return max(0.1, min(1.0, score))


def _calculate_recurring_score(
    recurring_patterns: list,
    total_transactions: int
) -> float:
    """반복성 점수 계산
    - 반복 패턴이 많을수록 반복형
    """
    if total_transactions == 0:
        return 0.5
    
    recurring_count = len(recurring_patterns)
    
    # 반복 패턴 비율
    ratio = min(1.0, recurring_count / max(total_transactions * 0.15, 1))
    return max(0.0, min(1.0, ratio))


def _calculate_saving_score(
    savings_opportunities: list,
    df: pd.DataFrame
) -> float:
    """절약성 점수 계산
    - 절약 기회가 적을수록 (현재 잘 절약 중) 절약형
    """
    if df.empty:
        return 0.5
    
    # 절약 기회가 많다는 건 현재 소비가 많다는 의미
    savings_count = len(savings_opportunities)
    
    # 평균 거래액 계산
    avg_amount = df["금액"].mean()
    
    # 절약 기회가 적고, 평균 거래액이 낮을수록 절약형
    savings_ratio = min(1.0, savings_count / 5.0)  # 최대 5개 기준
    
    # 평균 거래액 정규화 (10만원 기준)
    amount_ratio = min(1.0, avg_amount / 100000)
    
    # 절약 기회 적고, 평균 거래액 낮으면 높은 점수
    score = (1 - savings_ratio) * 0.6 + (1 - amount_ratio) * 0.4
    return max(0.0, min(1.0, score))


# --------------------------------
# private functions - Type Determination
# --------------------------------
def _determine_type(
    planning: float,
    regular: float,
    recurring: float,
    saving: float
) -> str:
    """점수를 바탕으로 유형 결정
    
    Returns:
        4자리 유형 코드 (예: "PRHS")
    """
    # 차원 1: Planning (P) vs Impulse (I)
    dim1 = "P" if planning >= 0.5 else "I"
    
    # 차원 2: Regular (R) vs Irregular (U)
    dim2 = "R" if regular >= 0.5 else "U"
    
    # 차원 3: Recurring (H) vs Diverse (V)
    # H = Habitual (습관적), V = Varied (다양성)
    dim3 = "H" if recurring >= 0.5 else "V"
    
    # 차원 4: Saver (S) vs Spender (E)
    # S = Saver (절약형), E = Expender/Spender (소비형)
    dim4 = "S" if saving >= 0.5 else "E"
    
    return f"{dim1}{dim2}{dim3}{dim4}"


# --------------------------------
# private functions - Response Building
# --------------------------------
def _build_personality_response(
    personality_info: dict,
    personality_type: str | None = None,
    scores: dict | None = None
) -> dict:
    """소비 성향 응답 구성"""
    default_scores = {
        "planning": 0.5,
        "regular": 0.5,
        "recurring": 0.5,
        "saving": 0.5,
    }
    
    return {
        "type": personality_type or "Unknown",
        "name": personality_info["name"],
        "description": personality_info["description"],
        "traits": personality_info["traits"],
        "character_icon": personality_info["character_icon"],
        "character_image": personality_info["character_image"],
        "advice": personality_info["advice"],
        "scores": {
            k: round(v, 2) for k, v in (scores or default_scores).items()
        },
    }