from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from app.service.overspending_service import (
    analyze_overspending,
    load_overspending_rules,
    save_overspending_rules,
    add_overspending_rule,
    update_overspending_rule,
    delete_overspending_rule,
)
import calendar

analysis_router = APIRouter(prefix="/analysis", tags=["분석"])

class OverspendingRule(BaseModel):
    id: Optional[int] = None
    name: str
    category_filter: str
    enabled: bool = True
    per_transaction: Optional[int] = None
    weekly_count: Optional[int] = None
    monthly_count: Optional[int] = None
    monthly_total: Optional[int] = None
    time_filter: Optional[List[int]] = None


class RulesUpdate(BaseModel):
    rules: List[OverspendingRule]

@analysis_router.get("/overspending")
def get_overspending_analysis(
    year: int | None = None,
    month: int | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
):
    """과소비 패턴 분석"""
    try:
        if year and month:
            # 다음 달 0일 = 해당 달 마지막 날
            last_day = calendar.monthrange(year, month)[1]
            start_date = f"{year:04d}-{month:02d}-01"
            end_date = f"{year:04d}-{month:02d}-{last_day:02d}"
        patterns = analyze_overspending(start_date=start_date, end_date=end_date)
        return {"count": len(patterns), "patterns": patterns}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="과소비 분석 중 오류 발생")

@analysis_router.get("/rules")
def get_overspending_rules():
    """과소비 규칙 조회"""
    try:
        rules = load_overspending_rules()
        # time_filter를 리스트로 변환 (JSON 응답을 위해)
        rules_response = []
        for rule in rules:
            rule_dict = rule.copy()
            if 'time_filter' in rule_dict and isinstance(rule_dict['time_filter'], tuple):
                rule_dict['time_filter'] = list(rule_dict['time_filter'])
            rules_response.append(rule_dict)
        return {"rules": rules_response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"규칙 조회 실패: {str(e)}")

@analysis_router.put("/rules")
def update_overspending_rules(rules_update: RulesUpdate):
    """과소비 규칙 전체 수정"""
    try:
        # Pydantic 모델을 dict로 변환
        rules_dict = [rule.model_dump(exclude_none=True) for rule in rules_update.rules]
        
        # time_filter를 튜플로 변환 (내부 처리용)
        for rule in rules_dict:
            if 'time_filter' in rule and isinstance(rule['time_filter'], list):
                rule['time_filter'] = tuple(rule['time_filter'])
        
        success = save_overspending_rules(rules_dict)
        if not success:
            raise HTTPException(status_code=500, detail="규칙 저장 실패")
        
        return {"message": "규칙이 성공적으로 저장되었습니다", "count": len(rules_dict)}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"규칙 수정 실패: {str(e)}")

@analysis_router.post("/rules")
def create_overspending_rule(rule: OverspendingRule):
    """과소비 규칙 추가"""
    try:
        rule_dict = rule.model_dump(exclude_none=True)
        
        # time_filter를 튜플로 변환
        if 'time_filter' in rule_dict and isinstance(rule_dict['time_filter'], list):
            rule_dict['time_filter'] = tuple(rule_dict['time_filter'])
        
        new_rule = add_overspending_rule(rule_dict)
        
        # time_filter를 리스트로 변환 (응답용)
        if 'time_filter' in new_rule and isinstance(new_rule['time_filter'], tuple):
            new_rule['time_filter'] = list(new_rule['time_filter'])
        
        return {"message": "규칙이 추가되었습니다", "rule": new_rule}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"규칙 추가 실패: {str(e)}")

@analysis_router.put("/rules/{rule_id}")
def update_single_overspending_rule(rule_id: int, rule: OverspendingRule):
    """과소비 규칙 단일 수정"""
    try:
        rule_dict = rule.model_dump(exclude_none=True)
        rule_dict['id'] = rule_id
        
        # time_filter를 튜플로 변환
        if 'time_filter' in rule_dict and isinstance(rule_dict['time_filter'], list):
            rule_dict['time_filter'] = tuple(rule_dict['time_filter'])
        
        updated_rule = update_overspending_rule(rule_id, rule_dict)
        
        if not updated_rule:
            raise HTTPException(status_code=404, detail=f"규칙 ID {rule_id}를 찾을 수 없습니다")
        
        # time_filter를 리스트로 변환 (응답용)
        if 'time_filter' in updated_rule and isinstance(updated_rule['time_filter'], tuple):
            updated_rule['time_filter'] = list(updated_rule['time_filter'])
        
        return {"message": "규칙이 수정되었습니다", "rule": updated_rule}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"규칙 수정 실패: {str(e)}")


@analysis_router.delete("/rules/{rule_id}")
def delete_overspending_rule_endpoint(rule_id: int):
    """과소비 규칙 삭제"""
    try:
        success = delete_overspending_rule(rule_id)
        if not success:
            raise HTTPException(status_code=404, detail=f"규칙 ID {rule_id}를 찾을 수 없습니다")
        
        return {"message": f"규칙 ID {rule_id}가 삭제되었습니다"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"규칙 삭제 실패: {str(e)}")