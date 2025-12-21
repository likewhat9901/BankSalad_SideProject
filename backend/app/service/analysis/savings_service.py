import pandas as pd
import calendar
from config import get_parquet_path
from logger import setup_logger
from app.service.analysis.recurring_service import analyze_recurring
from app.service.analysis.overspending_service import analyze_overspending

logger = setup_logger(__name__)


def analyze_savings_opportunities(
    year: int | None = None,
    month: int | None = None,
) -> list[dict]:
    """절약 기회 분석 (Top 3)
    
    절약 추천 기준:
    1. 반복 소비 패턴: 빈도 줄이기 (예: 주 2회 → 주 1회)
    2. 과소비 패턴: 규칙 위반 금액의 30% 절약 가능
    3. 카테고리별 초과 지출: 평균 대비 초과 금액의 20% 절약 가능
    
    Args:
        year: 연도 (선택)
        month: 월 (선택)
    
    Returns:
        절약 기회 리스트 (절약 가능 금액 내림차순, 최대 3개)
    """
    parquet_path = get_parquet_path()
    
    if not parquet_path.exists():
        logger.warning("parquet 파일 없음 - 빈 결과 반환")
        return []
    
    try:
        opportunities = []
        
        # 1. 반복 소비 패턴 기반 절약 기회
        recurring_opportunities = _analyze_recurring_savings(year, month)
        opportunities.extend(recurring_opportunities)
        
        # 2. 과소비 패턴 기반 절약 기회
        overspending_opportunities = _analyze_overspending_savings(year, month)
        opportunities.extend(overspending_opportunities)
        
        # 3. 카테고리별 초과 지출 기반 절약 기회
        category_opportunities = _analyze_category_savings(year, month)
        opportunities.extend(category_opportunities)
        
        # 절약 가능 금액 기준 내림차순 정렬 후 Top 3
        opportunities.sort(key=lambda x: x["savings_amount"], reverse=True)
        top3 = opportunities[:3]
        
        logger.info(f"절약 기회 {len(top3)}건 추천")
        return top3
        
    except Exception as e:
        logger.error(f"절약 분석 실패: {e}")
        raise


def _analyze_recurring_savings(year: int | None, month: int | None) -> list[dict]:
    """반복 소비 패턴 기반 절약 기회"""
    opportunities = []
    
    patterns = analyze_recurring(year=year, month=month, min_count=3)
    
    for pattern in patterns:
        count = pattern["count"]
        total_amount = pattern["total_amount"]
        average_amount = pattern["average_amount"]
        
        # 반복 횟수가 많을수록 절약 기회 (예: 주 2회 → 주 1회로 줄이면 50% 절약)
        if count >= 4:  # 월 4회 이상이면 절약 기회
            # 절약 가능 금액 = 평균 금액 * (현재 빈도 - 권장 빈도)
            # 예: 월 8회 → 월 4회로 줄이면 50% 절약
            recommended_frequency = max(2, count // 2)  # 최소 2회는 유지
            savings_amount = average_amount * (count - recommended_frequency)
            
            if savings_amount > 10000:  # 최소 1만원 이상 절약 가능한 것만
                opportunities.append({
                    "type": "recurring",
                    "title": f"{pattern['merchant']} 반복 소비 줄이기",
                    "description": f"월 {count}회 → 월 {recommended_frequency}회로 줄이면",
                    "current_amount": total_amount,
                    "savings_amount": int(savings_amount),
                    "category": pattern["category"],
                    "merchant": pattern["merchant"],
                    "current_frequency": count,
                    "recommended_frequency": recommended_frequency,
                })
    
    return opportunities


def _analyze_overspending_savings(year: int | None, month: int | None) -> list[dict]:
    """과소비 패턴 기반 절약 기회"""
    opportunities = []
    
    if year and month:
        last_day = calendar.monthrange(year, month)[1]
        start_date = f"{year:04d}-{month:02d}-01"
        end_date = f"{year:04d}-{month:02d}-{last_day:02d}"
    else:
        start_date = None
        end_date = None
    
    patterns = analyze_overspending(start_date=start_date, end_date=end_date)
    
    for pattern in patterns:
        total_amount = pattern["total_amount"]
        # 과소비 금액의 30% 절약 가능 (규칙을 지키면)
        savings_amount = int(total_amount * 0.3)
        
        if savings_amount > 10000:  # 최소 1만원 이상
            opportunities.append({
                "type": "overspending",
                "title": f"{pattern['category']} 과소비 줄이기",
                "description": "과소비 규칙을 지키면",
                "current_amount": total_amount,
                "savings_amount": savings_amount,
                "category": pattern["category"],
                "reasons": pattern["reasons"],
            })
    
    return opportunities


def _analyze_category_savings(year: int | None, month: int | None) -> list[dict]:
    """카테고리별 초과 지출 기반 절약 기회"""
    opportunities = []
    
    parquet_path = get_parquet_path()
    df = pd.read_parquet(parquet_path)
    
    # 날짜 필터링
    if year and month:
        last_day = calendar.monthrange(year, month)[1]
        start_date = pd.Timestamp(f"{year:04d}-{month:02d}-01")
        end_date = pd.Timestamp(f"{year:04d}-{month:02d}-{last_day:02d}")
        df = df[(df["거래일시"] >= start_date) & (df["거래일시"] <= end_date)]
    
    if df.empty:
        return []
    
    # 지출 데이터만
    df = df[df["타입"] == "지출"].copy()
    df["금액"] = df["금액"].abs()
    
    if df.empty:
        return []
    
    # 카테고리별 집계
    category_stats = df.groupby("대분류").agg({
        "금액": ["sum", "mean", "count"]
    }).reset_index()
    category_stats.columns = ["category", "total", "average", "count"]
    
    # 전체 평균 대비 초과 지출 카테고리 찾기
    overall_avg = df["금액"].mean()
    
    for _, row in category_stats.iterrows():
        category = row["category"]
        category_avg = row["average"]
        category_total = int(row["total"])
        count = int(row["count"])
        
        # 카테고리 평균이 전체 평균보다 1.5배 이상이면 절약 기회
        if category_avg > overall_avg * 1.5 and count >= 3:
            excess_amount = (category_avg - overall_avg) * count
            savings_amount = int(excess_amount * 0.2)  # 초과 금액의 20% 절약 가능
            
            if savings_amount > 10000:
                opportunities.append({
                    "type": "category",
                    "title": f"{category} 지출 줄이기",
                    "description": f"평균 거래액을 줄이면",
                    "current_amount": category_total,
                    "savings_amount": savings_amount,
                    "category": category,
                    "current_avg": int(category_avg),
                    "recommended_avg": int(overall_avg),
                })
    
    return opportunities