"""과소비 분석 서비스 테스트"""
import pytest
import pandas as pd
from datetime import datetime

from app.domains.overspending.services.pattern_service import (
    _make_reason,
    _filter_by_rule,
    _check_weekly_count,
    _check_monthly_count,
    _check_monthly_total,
    _check_per_transaction,
    _enrich_with_analysis_data,
)
from app.domains.overspending.services.recurring_service import (
    _get_time_range,
    _create_pattern_dict,
)


# ================================
# Pattern Service 테스트
# ================================
class TestMakeReason:
    """_make_reason 함수 테스트"""
    
    def test_reason_딕셔너리_생성(self):
        """reason 딕셔너리 정상 생성"""
        result = _make_reason("high_frequency", 10, "주 3회 이상")
        
        assert result["type"] == "high_frequency"
        assert result["count"] == 10
        assert result["message"] == "주 3회 이상"


class TestEnrichWithAnalysisData:
    """_enrich_with_analysis_data 함수 테스트"""
    
    def test_시간_주_월_컬럼_추가(self):
        """hour, week, month 컬럼이 추가되는지 확인"""
        df = pd.DataFrame({
            "거래일시": pd.to_datetime(["2025-01-15 14:30:00", "2025-02-20 09:15:00"]),
            "금액": [10000, 20000],
        })
        
        result = _enrich_with_analysis_data(df)
        
        assert "hour" in result.columns
        assert "week" in result.columns
        assert "month" in result.columns
        assert result.iloc[0]["hour"] == 14
        assert result.iloc[1]["hour"] == 9


class TestFilterByRule:
    """_filter_by_rule 함수 테스트"""
    
    @pytest.fixture
    def sample_df(self):
        """테스트용 DataFrame"""
        return pd.DataFrame({
            "대분류": ["식비", "식비", "교통", "쇼핑"],
            "금액": [10000, 15000, 5000, 50000],
            "hour": [14, 22, 10, 15],
        })
    
    def test_카테고리_필터링(self, sample_df):
        """카테고리로 필터링"""
        rule = {"category_filter": "식비"}
        
        result = _filter_by_rule(sample_df, rule)
        
        assert len(result) == 2
        assert all(result["대분류"] == "식비")
    
    def test_시간대_필터링(self, sample_df):
        """시간대로 필터링 (야간: 22시~6시)"""
        rule = {
            "category_filter": "식비",
            "time_filter": [22, 6]  # 야간
        }
        
        result = _filter_by_rule(sample_df, rule)
        
        assert len(result) == 1
        assert result.iloc[0]["hour"] == 22
    
    def test_존재하지_않는_카테고리(self, sample_df):
        """존재하지 않는 카테고리는 빈 DataFrame"""
        rule = {"category_filter": "여행"}
        
        result = _filter_by_rule(sample_df, rule)
        
        assert result.empty


class TestCheckWeeklyCount:
    """_check_weekly_count 함수 테스트"""
    
    def test_주3회_이상이면_감지(self):
        """주 3회 이상이면 과소비로 감지"""
        df = pd.DataFrame({
            "week": [1, 1, 1, 1, 2, 2],  # 1주차 4회, 2주차 2회
            "금액": [5000] * 6,
        })
        
        result = _check_weekly_count(df, threshold=3, rule_name="테스트")
        
        assert result is not None
        assert result["type"] == "high_frequency"
        assert "주 3회 이상" in result["message"]
    
    def test_주3회_미만이면_None(self):
        """주 3회 미만이면 None"""
        df = pd.DataFrame({
            "week": [1, 1, 2, 2],  # 각 주차 2회씩
            "금액": [5000] * 4,
        })
        
        result = _check_weekly_count(df, threshold=3, rule_name="테스트")
        
        assert result is None


class TestCheckMonthlyTotal:
    """_check_monthly_total 함수 테스트"""
    
    def test_월총액_초과시_감지(self):
        """월 총액 초과 시 감지"""
        df = pd.DataFrame({
            "month": pd.to_datetime(["2025-01", "2025-01"]).to_period("M"),
            "금액": [60000, 50000],  # 총 11만원
        })
        
        result = _check_monthly_total(df, threshold=100000, rule_name="테스트")
        
        assert result is not None
        assert result["type"] == "high_monthly"
    
    def test_월총액_미만이면_None(self):
        """월 총액 미만이면 None"""
        df = pd.DataFrame({
            "month": pd.to_datetime(["2025-01", "2025-01"]).to_period("M"),
            "금액": [30000, 20000],  # 총 5만원
        })
        
        result = _check_monthly_total(df, threshold=100000, rule_name="테스트")
        
        assert result is None


class TestCheckPerTransaction:
    """_check_per_transaction 함수 테스트"""
    
    def test_건당_고액_감지(self):
        """건당 10만원 이상 감지"""
        df = pd.DataFrame({
            "금액": [150000, 50000, 200000],
        })
        
        result = _check_per_transaction(df, threshold=100000, rule_name="테스트")
        
        assert result is not None
        assert result["type"] == "high_amount"
        assert result["count"] == 2  # 2건
    
    def test_건당_고액_없으면_None(self):
        """건당 고액 없으면 None"""
        df = pd.DataFrame({
            "금액": [50000, 30000, 20000],
        })
        
        result = _check_per_transaction(df, threshold=100000, rule_name="테스트")
        
        assert result is None


# ================================
# Recurring Service 테스트
# ================================
class TestGetTimeRange:
    """_get_time_range 함수 테스트"""
    
    @pytest.mark.parametrize("hour,expected", [
        (0, "00:00-06:00"),
        (3, "00:00-06:00"),
        (5, "00:00-06:00"),
        (6, "06:00-12:00"),
        (9, "06:00-12:00"),
        (11, "06:00-12:00"),
        (12, "12:00-18:00"),
        (15, "12:00-18:00"),
        (17, "12:00-18:00"),
        (18, "18:00-24:00"),
        (21, "18:00-24:00"),
        (23, "18:00-24:00"),
    ])
    def test_시간대_범위_변환(self, hour, expected):
        """시간별 올바른 범위 반환"""
        result = _get_time_range(hour)
        assert result == expected


class TestCreatePatternDict:
    """_create_pattern_dict 함수 테스트"""
    
    def test_반복패턴_딕셔너리_생성(self):
        """반복 패턴 딕셔너리 정상 생성"""
        group = pd.DataFrame({
            "거래일시": pd.to_datetime([
                "2025-01-01 14:00:00",
                "2025-01-08 14:00:00",
                "2025-01-15 14:00:00",
            ]),
            "금액": [5000, 5000, 5000],
            "day_of_week": ["Wednesday", "Wednesday", "Wednesday"],
        })
        
        result = _create_pattern_dict(
            group=group,
            merchant="스타벅스",
            time_range="12:00-18:00",
            category="카페",
            payment_method="카드",
            count=3
        )
        
        assert result["merchant"] == "스타벅스"
        assert result["count"] == 3
        assert result["total_amount"] == 15000
        assert result["average_amount"] == 5000
        assert result["day_of_week"] == "Wednesday"
        assert result["period_days"] == 7  # 7일 주기