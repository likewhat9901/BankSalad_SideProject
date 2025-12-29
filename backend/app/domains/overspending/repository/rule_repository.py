import json
from pathlib import Path
from logger import setup_logger

from app.common.config.path_provider import get_file_path

logger = setup_logger(__name__)

# --------------------------------
# public functions
# --------------------------------
def load_rules_from_file(include_disabled: bool = False) -> list[dict]:
    """규칙 파일에서 JSON 데이터 로드
    
    Args:
        include_disabled: 비활성 규칙 포함 여부 (기본값: False)
    
    Returns:
        규칙 리스트 (enabled 필터링 적용)
    """
    rules_path = _get_rules_path()
    data = _load_json_file(rules_path)

    rules = data.get("rules")
    if not isinstance(rules, list):
        raise ValueError("규칙 파일 형식이 올바르지 않습니다")

    # enabled 필터링
    if not include_disabled:
        rules = [r for r in rules if r.get("enabled", True)]

    return rules

def save_rules_to_file(rules: list[dict]) -> bool:
    """과소비 규칙을 JSON 파일에 저장"""
    rules_path = _get_rules_path()
    data = {"rules": rules}
    with open(rules_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


# --------------------------------
# private functions
# --------------------------------
def _get_rules_path() -> Path:
    """규칙 파일 경로"""
    path = get_file_path("overspending_rules")
    # 디렉토리가 없으면 생성
    path.parent.mkdir(parents=True, exist_ok=True)
    return path

def _load_json_file(path: Path) -> dict:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        raise ValueError(f"JSON 파싱 실패: {e}")
