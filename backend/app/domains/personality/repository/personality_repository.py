import pandas as pd
from logger import setup_logger

from app.common.utils import (
    parse_date_params,
    filter_by_date_range,
    filter_expense_only,
)
from app.domains.transaction.repository import load_transactions
from app.domains.personality.models.personality_data import personality_data

logger = setup_logger(__name__)


def load_expense_transactions(
    year: int | None = None,
    month: int | None = None
) -> pd.DataFrame:
    """지출 거래 데이터 로드 및 필터링"""
    # 날짜 파라미터 파싱
    start_date, end_date = parse_date_params(year, month, None, None)
    
    # 데이터 로드
    df = load_transactions()
    
    df = filter_by_date_range(df, start_date, end_date)
    df = filter_expense_only(df)
    
    return df


def get_personality_info(personality_type: str) -> dict:
    """유형별 정보 조회
    
    Args:
        personality_type: 유형 코드 (예: "PRHS")
    
    Returns:
        유형 정보 딕셔너리
    """
    return personality_data.get(personality_type, personality_data["Unknown"])


def get_default_personality() -> dict:
    """기본 유형 정보 반환"""
    return personality_data["Unknown"]