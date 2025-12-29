import calendar
from typing import Optional, Tuple


def get_month_date_range(year: int, month: int) -> Tuple[str, str]:
    """연도와 월을 받아서 해당 월의 시작일과 종료일을 반환
    
    Args:
        year: 연도 (예: 2025)
        month: 월 (1-12)
    
    Returns:
        (start_date, end_date) 튜플 (YYYY-MM-DD 형식)
    
    Example:
        >>> get_month_date_range(2025, 12)
        ('2025-12-01', '2025-12-31')
    """
    last_day = calendar.monthrange(year, month)[1]
    start_date = f"{year:04d}-{month:02d}-01"
    end_date = f"{year:04d}-{month:02d}-{last_day:02d}"
    return start_date, end_date


def parse_date_params(
    year: Optional[int] = None,
    month: Optional[int] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
) -> Tuple[Optional[str], Optional[str]]:
    """year/month 또는 start_date/end_date를 받아서 
    start_date와 end_date를 반환
    
    Args:
        year: 연도
        month: 월
        start_date: 시작일 (YYYY-MM-DD)
        end_date: 종료일 (YYYY-MM-DD)
    
    Returns:
        (start_date, end_date) 튜플
    
    Example:
        >>> parse_date_params(year=2025, month=12)
        ('2025-12-01', '2025-12-31')
        >>> parse_date_params(start_date='2025-12-01', end_date='2025-12-31')
        ('2025-12-01', '2025-12-31')
    """
    if year and month:
        return get_month_date_range(year, month)
    return start_date, end_date