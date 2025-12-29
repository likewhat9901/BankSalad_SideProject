"""소비 성향 서비스 테스트"""
from app.domains.personality.services.personality_service import (
    _determine_type,
    _calculate_planning_score,
)


class TestDetermineType:
    """_determine_type 함수 테스트"""
    
    def test_모든_점수_높으면_PRHS(self):
        """모든 점수가 0.5 이상이면 PRHS"""
        result = _determine_type(
            planning=0.8,
            regular=0.7,
            recurring=0.6,
            saving=0.9
        )
        assert result == "PRHS"
    
    def test_모든_점수_낮으면_IUVE(self):
        """모든 점수가 0.5 미만이면 IUVE"""
        result = _determine_type(
            planning=0.3,
            regular=0.2,
            recurring=0.4,
            saving=0.1
        )
        assert result == "IUVE"
    
    def test_경계값_0점5는_높은쪽(self):
        """0.5는 높은 쪽으로 분류"""
        result = _determine_type(
            planning=0.5,
            regular=0.5,
            recurring=0.5,
            saving=0.5
        )
        assert result == "PRHS"


class TestCalculatePlanningScore:
    """_calculate_planning_score 함수 테스트"""
    
    def test_거래없으면_0점5(self):
        """거래가 없으면 0.5 반환"""
        result = _calculate_planning_score(
            recurring_patterns=[],
            overspending_patterns=[],
            total_transactions=0
        )
        assert result == 0.5
    
    def test_반복패턴_많으면_높은점수(self):
        """반복 패턴이 많으면 높은 점수"""
        result = _calculate_planning_score(
            recurring_patterns=[{}, {}, {}, {}],  # 4개
            overspending_patterns=[],
            total_transactions=10
        )
        assert result > 0.5
    
    def test_과소비_많으면_낮은점수(self):
        """과소비가 많으면 낮은 점수"""
        result = _calculate_planning_score(
            recurring_patterns=[],
            overspending_patterns=[{}, {}, {}, {}, {}],  # 5개
            total_transactions=10
        )
        assert result < 0.5