"""절약 기회 서비스 테스트"""
import pandas as pd
from app.domains.saving.services.savings_service import (
    _create_recurring_opportunity,
    _create_overspending_opportunity,
    _create_category_opportunity,
    _calculate_category_stats,
)


class TestCreateRecurringOpportunity:
    """_create_recurring_opportunity 함수 테스트"""
    
    def test_4회_이상이면_절약기회_생성(self):
        """월 4회 이상 반복 소비는 절약 기회 생성"""
        pattern = {
            "merchant": "스타벅스",
            "category": "카페",
            "count": 8,
            "average_amount": 5000,
            "total_amount": 40000,
        }
        result = _create_recurring_opportunity(pattern)
        
        assert result is not None
        assert result["type"] == "recurring"
        assert result["merchant"] == "스타벅스"
        assert result["current_frequency"] == 8
        assert result["recommended_frequency"] == 4  # 8 // 2
    
    def test_3회_이하면_None_반환(self):
        """월 3회 이하는 절약 기회 생성 안 함"""
        pattern = {
            "merchant": "스타벅스",
            "category": "카페",
            "count": 3,
            "average_amount": 5000,
            "total_amount": 15000,
        }
        result = _create_recurring_opportunity(pattern)
        
        assert result is None
    
    def test_절약금액_1만원_이하면_None(self):
        """절약 가능 금액이 1만원 이하면 제외"""
        pattern = {
            "merchant": "편의점",
            "category": "생활",
            "count": 4,
            "average_amount": 2000,  # 낮은 금액
            "total_amount": 8000,
        }
        result = _create_recurring_opportunity(pattern)
        
        assert result is None


class TestCreateOverspendingOpportunity:
    """_create_overspending_opportunity 함수 테스트"""
    
    def test_과소비_패턴이면_절약기회_생성(self):
        """과소비 패턴에서 절약 기회 생성 (30% 절약)"""
        pattern = {
            "category": "쇼핑",
            "total_amount": 100000,
            "reasons": ["주말 과소비"],
        }
        result = _create_overspending_opportunity(pattern)
        
        assert result is not None
        assert result["type"] == "overspending"
        assert result["savings_amount"] == 30000  # 100000 * 0.3
    
    def test_절약금액_1만원_이하면_None(self):
        """절약 가능 금액이 1만원 이하면 제외"""
        pattern = {
            "category": "간식",
            "total_amount": 20000,  # 30% = 6000원
            "reasons": ["야식"],
        }
        result = _create_overspending_opportunity(pattern)
        
        assert result is None


class TestCreateCategoryOpportunity:
    """_create_category_opportunity 함수 테스트"""
    
    def test_평균1점5배_이상이면_절약기회(self):
        """카테고리 평균이 전체 평균의 1.5배 이상이면 절약 기회"""
        row = pd.Series({
            "category": "외식",
            "total": 300000,
            "average": 30000,  # 전체 평균의 1.5배 이상
            "count": 10,
        })
        overall_avg = 15000
        
        result = _create_category_opportunity(row, overall_avg)
        
        assert result is not None
        assert result["type"] == "category"
        assert result["category"] == "외식"
    
    def test_평균1점5배_미만이면_None(self):
        """카테고리 평균이 1.5배 미만이면 제외"""
        row = pd.Series({
            "category": "교통",
            "total": 50000,
            "average": 10000,
            "count": 5,
        })
        overall_avg = 10000  # 동일
        
        result = _create_category_opportunity(row, overall_avg)
        
        assert result is None
    
    def test_3회_미만이면_None(self):
        """거래 횟수 3회 미만이면 제외"""
        row = pd.Series({
            "category": "명품",
            "total": 1000000,
            "average": 500000,  # 평균 높음
            "count": 2,  # 2회만
        })
        overall_avg = 20000
        
        result = _create_category_opportunity(row, overall_avg)
        
        assert result is None


class TestCalculateCategoryStats:
    """_calculate_category_stats 함수 테스트"""
    
    def test_카테고리별_통계_계산(self):
        """카테고리별 합계/평균/건수 계산"""
        df = pd.DataFrame({
            "대분류": ["식비", "식비", "교통", "교통", "교통"],
            "금액": [10000, 20000, 5000, 5000, 5000],
        })
        
        result = _calculate_category_stats(df)
        
        assert len(result) == 2
        
        # 식비: 합계 30000, 평균 15000, 2건
        food = result[result["category"] == "식비"].iloc[0]
