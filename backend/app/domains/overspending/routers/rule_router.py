from fastapi import APIRouter, HTTPException

from app.domains.overspending.services import (
    get_overspending_rules,
    save_overspending_rules,
    add_overspending_rule,
    update_overspending_rule,
    delete_overspending_rule,
)
from app.domains.overspending.model import (
    OverspendingRule,
    RulesUpdate,
)

rule_router = APIRouter(prefix="/rules", tags=["과소비 규칙"])


@rule_router.get("/")
def read_overspending_rules():
    """과소비 규칙 조회"""
    rules = get_overspending_rules()
    return {"rules": rules}


@rule_router.put("/")
def update_overspending_rules(rules_update: RulesUpdate):
    """과소비 규칙 전체 수정"""
    rules_dict = [rule.model_dump(exclude_none=True) for rule in rules_update.rules]
    success = save_overspending_rules(rules_dict)
    
    if not success:
        raise HTTPException(status_code=500, detail="규칙 저장 실패")
    
    return {"message": "규칙이 성공적으로 저장되었습니다", "count": len(rules_dict)}


@rule_router.post("/")
def create_overspending_rule(rule: OverspendingRule):
    """과소비 규칙 추가"""
    rule_dict = rule.model_dump(exclude_none=True)
    new_rule = add_overspending_rule(rule_dict)
    
    return {"message": "규칙이 추가되었습니다", "rule": new_rule}


@rule_router.put("/{rule_id}")
def update_single_overspending_rule(rule_id: int, rule: OverspendingRule):
    """과소비 규칙 단일 수정"""
    rule_dict = rule.model_dump(exclude_none=True)
    rule_dict['id'] = rule_id
    
    updated_rule = update_overspending_rule(rule_id, rule_dict)
    
    if not updated_rule:
        raise HTTPException(status_code=404, detail=f"규칙 ID {rule_id}를 찾을 수 없습니다")
    
    return {"message": "규칙이 수정되었습니다", "rule": updated_rule}


@rule_router.delete("/{rule_id}")
def delete_overspending_rule_endpoint(rule_id: int):
    """과소비 규칙 삭제"""
    success = delete_overspending_rule(rule_id)
    
    if not success:
        raise HTTPException(status_code=404, detail=f"규칙 ID {rule_id}를 찾을 수 없습니다")
    
    return {"message": f"규칙 ID {rule_id}가 삭제되었습니다"}

