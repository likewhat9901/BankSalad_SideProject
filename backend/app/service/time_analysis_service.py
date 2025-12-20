import pandas as pd
import calendar
from config import get_parquet_path
from logger import setup_logger

logger = setup_logger(__name__)


def analyze_time_based_spending(
    year: int | None = None,
    month: int | None = None,
) -> list[dict]:
    """시간대 소비 분석 (충동 지점 탐지)
    
    Args:
        year: 연도 (선택)
        month: 월 (선택)
    
    Returns:
        시간대별 소비 패턴 리스트
    """
    parquet_path = get_parquet_path()
    
    if not parquet_path.exists():
        logger.warning("parquet 파일 없음 - 빈 결과 반환")
        return []
    
    try:
        # 데이터 로드
        df = pd.read_parquet(parquet_path)
        
        # 날짜 필터링
        if year and month:
            last_day = calendar.monthrange(year, month)[1]
            start_date = pd.Timestamp(f"{year:04d}-{month:02d}-01")
            end_date = pd.Timestamp(f"{year:04d}-{month:02d}-{last_day:02d}")
            df = df[(df["거래일시"] >= start_date) & (df["거래일시"] <= end_date)]
        
        if df.empty:
            return []
        
        # 지출 데이터만 필터링
        df = df[df["타입"] == "지출"].copy()
        df["금액"] = df["금액"].abs()
        
        if df.empty:
            return []
        
        # 날짜 데이터 타입 확인
        if not pd.api.types.is_datetime64_any_dtype(df["거래일시"]):
            raise ValueError("거래일시 데이터 타입 오류")
        
        # 시간, 요일, 일자 데이터 추가
        df["hour"] = df["거래일시"].dt.hour
        df["day_of_week"] = df["거래일시"].dt.dayofweek  # 0=월요일, 6=일요일
        df["day"] = df["거래일시"].dt.day
        df["is_weekend"] = df["day_of_week"].isin([5, 6])  # 토, 일
        
        patterns = []
        
        # 1. 시간대별 패턴
        time_patterns = _analyze_time_patterns(df)
        patterns.extend(time_patterns)
        
        # 2. 월 초 패턴 (월급 직후)
        early_month_pattern = _analyze_early_month_pattern(df)
        if early_month_pattern:
            patterns.append(early_month_pattern)
        
        # 3. 주말 패턴
        weekend_pattern = _analyze_weekend_pattern(df)
        if weekend_pattern:
            patterns.append(weekend_pattern)
        
        # 총액 기준 내림차순 정렬
        patterns.sort(key=lambda x: x["total_amount"], reverse=True)
        
        logger.info(f"시간대 소비 패턴 {len(patterns)}건 감지")
        return patterns
        
    except Exception as e:
        logger.error(f"시간대 소비 분석 실패: {e}")
        raise


def _analyze_time_patterns(df: pd.DataFrame) -> list[dict]:
    """시간대별 소비 패턴 분석"""
    patterns = []
    
    # 시간대 정의
    time_ranges = [
        {"name": "새벽", "start": 0, "end": 6, "icon": "🌙"},
        {"name": "오전", "start": 6, "end": 12, "icon": "☀️"},
        {"name": "오후", "start": 12, "end": 18, "icon": "🌤️"},
        {"name": "저녁", "start": 18, "end": 22, "icon": "🌆"},
        {"name": "야간", "start": 22, "end": 24, "icon": "🌃"},
    ]
    
    for time_range in time_ranges:
        if time_range["end"] == 24:
            filtered = df[(df["hour"] >= time_range["start"]) & (df["hour"] < 24)]
        else:
            filtered = df[(df["hour"] >= time_range["start"]) & (df["hour"] < time_range["end"])]
        
        if filtered.empty:
            continue
        
        count = len(filtered)
        total_amount = int(filtered["금액"].sum())
        average_amount = int(total_amount / count) if count > 0 else 0
        
        patterns.append({
            "type": "time_range",
            "name": f"{time_range['icon']} {time_range['name']} ({time_range['start']:02d}~{time_range['end']:02d}시)",
            "description": f"{time_range['name']} 시간대 소비",
            "count": count,
            "total_amount": total_amount,
            "average_amount": average_amount,
            "time_range": f"{time_range['start']:02d}~{time_range['end']:02d}",
        })
    
    return patterns


def _analyze_early_month_pattern(df: pd.DataFrame) -> dict | None:
    """월 초 패턴 분석"""
    # 월 1일~5일 거래
    early_month = df[df["day"] <= 5].copy()
    
    if early_month.empty:
        return None
    
    count = len(early_month)
    total_amount = int(early_month["금액"].sum())
    average_amount = int(total_amount / count) if count > 0 else 0
    
    return {
        "type": "early_month",
        "name": "💰 월초 (1~5일)",
        "description": "월초 3~5일간의 소비 패턴",
        "count": count,
        "total_amount": total_amount,
        "average_amount": average_amount,
        "days": "1~5일",
    }


def _analyze_weekend_pattern(df: pd.DataFrame) -> dict | None:
    """주말 패턴 분석"""
    weekend = df[df["is_weekend"] == True].copy()
    
    if weekend.empty:
        return None
    
    # 주말 저녁 (18시 이후)
    weekend_evening = weekend[weekend["hour"] >= 18].copy()
    
    if weekend_evening.empty:
        return None
    
    count = len(weekend_evening)
    total_amount = int(weekend_evening["금액"].sum())
    average_amount = int(total_amount / count) if count > 0 else 0
    
    return {
        "type": "weekend_evening",
        "name": "🎉 주말 저녁",
        "description": "주말 저녁 시간대 소비",
        "count": count,
        "total_amount": total_amount,
        "average_amount": average_amount,
        "time_range": "18시 이후",
    }