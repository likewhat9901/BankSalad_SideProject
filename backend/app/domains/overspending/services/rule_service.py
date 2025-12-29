from logger import setup_logger

from app.domains.overspending.repository import *

logger = setup_logger(__name__)


# --------------------------------
# public functions
# --------------------------------
def get_overspending_rules(
    *,
    include_disabled: bool = False,
) -> list[dict]:
    """과소비 규칙 조회
    Args:
        include_disabled: 비활성 규칙 포함 여부
    Returns:
        list[dict]: 과소비 규칙 목록
    """
    # 과소비 규칙 조회
    rules = load_rules_from_file(include_disabled=include_disabled)
    logger.info(f"과소비 규칙 {len(rules)}개 로드 완료")
    return rules


def save_overspending_rules(rules: list[dict]) -> bool:
    """과소비 규칙들을 JSON 파일에 저장"""
    try:
        # 과소비 규칙 저장
        save_rules_to_file(rules)
        logger.info(f"과소비 규칙 {len(rules)}개 저장 완료")
        return True
    except Exception as e:
        logger.error(f"과소비 규칙 저장 실패: {e}")
        return False

def add_overspending_rule(rule: dict) -> dict:
    """과소비 규칙 추가"""
    rules = load_rules_from_file(include_disabled=True)  # 모든 규칙 로드
    
    # ID 자동 생성
    max_id = max([r.get('id', 0) for r in rules], default=0)
    rule['id'] = max_id + 1
    
    # 규칙 추가
    rules.append(rule)
    
    # 규칙 저장
    if not save_rules_to_file(rules):
        raise Exception("규칙 저장 실패")
    
    logger.info(f"규칙 추가 완료: {rule['name']} (ID: {rule['id']})")
    return rule


def update_overspending_rule(rule_id: int, updated_rule: dict) -> dict | None:
    """과소비 규칙 수정"""
    # 과소비 규칙 조회
    rules = load_rules_from_file(include_disabled=True)
    
    # ID로 규칙 인덱스 찾기
    rule_index = _find_rule_index_by_id(rules, rule_id)
    # ID로 규칙 인덱스가 없으면 규칙 수정 실패 반환
    if rule_index is None:
        logger.error(f"규칙 수정 실패: ID {rule_id} 없음")
        return None
    
    # 규칙 ID 업데이트
    updated_rule['id'] = rule_id
    rules[rule_index] = updated_rule
    
    # 규칙 저장
    if not save_rules_to_file(rules):
        logger.error(f"규칙 수정 실패: ID {rule_id} 저장 실패")
        return None
    
    logger.info(f"규칙 수정 완료: ID {rule_id}")
    return updated_rule


def delete_overspending_rule(rule_id: int) -> bool:
    """과소비 규칙 삭제"""
    # 과소비 규칙 조회
    rules = load_rules_from_file(include_disabled=True)
    # ID로 규칙 인덱스 찾기
    rule_index = _find_rule_index_by_id(rules, rule_id)
    # ID로 규칙 인덱스가 없으면 규칙 삭제 실패 반환
    if rule_index is None:
        logger.error(f"규칙 삭제 실패: ID {rule_id} 없음")
        return False
    
    # 규칙 삭제
    deleted_rule = rules.pop(rule_index)
    
    # 규칙 저장
    if not save_rules_to_file(rules):
        logger.error(f"규칙 삭제 실패: ID {rule_id} 저장 실패")
        return False
    
    logger.info(f"규칙 삭제 완료: {deleted_rule.get('name')} (ID: {rule_id})")
    return True


# --------------------------------
# private functions
# --------------------------------
def _find_rule_index_by_id(rules: list[dict], rule_id: int) -> int | None:
    """ID로 규칙 인덱스 찾기"""
    # ID로 규칙 인덱스 찾기
    for i, rule in enumerate(rules):
        # ID로 규칙 인덱스가 있으면 규칙 인덱스 반환
        if rule.get('id') == rule_id:
            return i
    return None