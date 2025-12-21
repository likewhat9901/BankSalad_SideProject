import pandas as pd
import json
from pathlib import Path
from config import get_parquet_path, APP_DIR
from logger import setup_logger

logger = setup_logger(__name__)


def get_rules_path() -> Path:
    """과소비 규칙 JSON 파일 경로"""
    # app/config/overspending_rules.json
    return APP_DIR / "config" / "overspending_rules.json"


def _convert_time_filter_to_tuple(rule: dict) -> dict:
    """time_filter를 튜플로 변환 (내부 처리용)"""
    if 'time_filter' in rule and isinstance(rule['time_filter'], list):
        rule['time_filter'] = tuple(rule['time_filter'])
    return rule


def _convert_time_filter_to_list(rule: dict) -> dict:
    """time_filter를 리스트로 변환 (JSON 저장용)"""
    rule_copy = rule.copy()
    if 'time_filter' in rule_copy and isinstance(rule_copy['time_filter'], tuple):
        rule_copy['time_filter'] = list(rule_copy['time_filter'])
    return rule_copy


def load_overspending_rules(include_disabled: bool = False) -> list[dict]:
    """JSON 파일에서 과소비 규칙 로드"""
    rules_path = get_rules_path()
    
    if not rules_path.exists():
        error_msg = f"규칙 파일이 없습니다: {rules_path}"
        logger.error(error_msg)
        raise FileNotFoundError(error_msg)
    
    try:
        with open(rules_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            rules = data.get('rules', [])
            
            if not rules:
                raise ValueError("규칙 파일에 규칙이 없습니다")
            
            # enabled 필터링 (분석용은 enabled만, 조회용은 모두)
            if not include_disabled:
                rules = [r for r in rules if r.get('enabled', True)]
            
            # time_filter를 튜플로 변환
            for rule in rules:
                _convert_time_filter_to_tuple(rule)
            
            logger.info(f"과소비 규칙 {len(rules)}개 로드 완료")
            return rules
            
    except json.JSONDecodeError as e:
        raise ValueError(f"JSON 파싱 오류: {e}")
    except Exception as e:
        logger.error(f"규칙 파일 로드 실패: {e}")
        raise


def save_overspending_rules(rules: list[dict]) -> bool:
    """과소비 규칙을 JSON 파일에 저장"""
    rules_path = get_rules_path()
    
    try:
        # time_filter를 리스트로 변환
        rules_to_save = [_convert_time_filter_to_list(rule) for rule in rules]
        
        # 디렉토리가 없으면 생성
        rules_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(rules_path, 'w', encoding='utf-8') as f:
            json.dump({"rules": rules_to_save}, f, ensure_ascii=False, indent=2)
        
        logger.info(f"과소비 규칙 {len(rules)}개 저장 완료")
        return True
        
    except Exception as e:
        logger.error(f"규칙 파일 저장 실패: {e}")
        return False


def _find_rule_index_by_id(rules: list[dict], rule_id: int) -> int | None:
    """ID로 규칙 인덱스 찾기"""
    for i, rule in enumerate(rules):
        if rule.get('id') == rule_id:
            return i
    return None


def add_overspending_rule(rule: dict) -> dict:
    """과소비 규칙 추가"""
    rules = load_overspending_rules(include_disabled=True)  # 모든 규칙 로드
    
    # ID 자동 생성
    max_id = max([r.get('id', 0) for r in rules], default=0)
    rule['id'] = max_id + 1
    
    rules.append(rule)
    
    if not save_overspending_rules(rules):
        raise Exception("규칙 저장 실패")
    
    logger.info(f"규칙 추가 완료: {rule['name']} (ID: {rule['id']})")
    return rule


def update_overspending_rule(rule_id: int, updated_rule: dict) -> dict | None:
    """과소비 규칙 수정"""
    rules = load_overspending_rules(include_disabled=True)
    
    rule_index = _find_rule_index_by_id(rules, rule_id)
    if rule_index is None:
        return None
    
    updated_rule['id'] = rule_id
    rules[rule_index] = updated_rule
    
    if not save_overspending_rules(rules):
        raise Exception("규칙 저장 실패")
    
    logger.info(f"규칙 수정 완료: ID {rule_id}")
    return updated_rule


def delete_overspending_rule(rule_id: int) -> bool:
    """과소비 규칙 삭제"""
    rules = load_overspending_rules(include_disabled=True)
    
    rule_index = _find_rule_index_by_id(rules, rule_id)
    if rule_index is None:
        return False
    
    deleted_rule = rules.pop(rule_index)
    
    if not save_overspending_rules(rules):
        raise Exception("규칙 저장 실패")
    
    logger.info(f"규칙 삭제 완료: {deleted_rule.get('name')} (ID: {rule_id})")
    return True


def analyze_overspending(start_date: str | None = None, end_date: str | None = None) -> list[dict]:
    """과소비 패턴 분석"""
    parquet_path = get_parquet_path()
    
    if not parquet_path.exists():
        logger.warning("parquet 파일 없음 - 빈 결과 반환")
        return []
    
    try:
        # 데이터 로드 및 필터링
        df = pd.read_parquet(parquet_path)
        
        if start_date:
            df = df[df["거래일시"] >= pd.to_datetime(start_date)]
        if end_date:
            df = df[df["거래일시"] <= pd.to_datetime(end_date)]
        if df.empty:
            return []

        # 지출 데이터만 필터링
        df = df[df["타입"] == "지출"].copy()
        df["금액"] = df["금액"].abs()
        
        if df.empty:
            return []

        # 날짜 데이터 타입 확인
        if not pd.api.types.is_datetime64_any_dtype(df["거래일시"]):
            raise ValueError("거래일시 데이터 타입 오류 - 거래내역 parquet 파일을 확인해주세요.")
        
        # 시간, 주, 월 데이터 추가
        df["hour"] = df["거래일시"].dt.hour
        df["week"] = df["거래일시"].dt.isocalendar().week
        df["month"] = df["거래일시"].dt.to_period("M")
        
        # 과소비 패턴 분석
        rules = load_overspending_rules()  # enabled만 로드
        results = [
            pattern for rule in rules
            if (pattern := _check_overspending(df, rule)) is not None
        ]
        
        logger.info(f"과소비 패턴 {len(results)}건 감지")
        return results
        
    except Exception as e:
        logger.error(f"과소비 분석 실패: {e}")
        raise


def _check_overspending(df: pd.DataFrame, rule: dict) -> dict | None:
    """범용 과소비 체크 함수"""
    # 데이터 필터링
    filtered_df = _filter_by_rule(df, rule)
    if filtered_df.empty:
        return None

    total_amount = int(filtered_df["금액"].sum())
    reasons = []
    
    # 조건 체크 함수들을 딕셔너리로 관리
    checkers = {
        'weekly_count': _check_weekly_count,
        'monthly_count': _check_monthly_count,
        'monthly_total': _check_monthly_total,
        'per_transaction': _check_per_transaction,
    }
    
    # 각 조건 체크
    for key, checker in checkers.items():
        if key in rule:
            reason = checker(filtered_df, rule[key], rule.get('name', ''))
            if reason:
                reasons.append(reason)

    if not reasons:
        return None
    
    return {
        "category": rule["name"],
        "total_amount": total_amount,
        "reasons": reasons
    }


def _filter_by_rule(df: pd.DataFrame, rule: dict) -> pd.DataFrame:
    """규칙에 따라 데이터 필터링"""
    # 카테고리 필터링
    filtered_df = df[df["대분류"] == rule["category_filter"]]
    if filtered_df.empty:
        return filtered_df
    
    # 시간대 필터 (선택)
    if "time_filter" in rule:
        start_hour, end_hour = rule["time_filter"]
        if start_hour > end_hour:
            time_mask = (filtered_df["hour"] >= start_hour) | (filtered_df["hour"] < end_hour)
        else:
            time_mask = (filtered_df["hour"] >= start_hour) & (filtered_df["hour"] < end_hour)
        filtered_df = filtered_df[time_mask]
    
    return filtered_df


def _check_weekly_count(df: pd.DataFrame, threshold: int, rule_name: str) -> dict | None:
    """주별 빈도 체크"""
    weekly_counts = df.groupby("week").size()
    high_freq = weekly_counts[weekly_counts >= threshold]
    if len(high_freq) > 0:
        return _make_reason(
            "high_frequency",
            int(weekly_counts.sum()),
            f"주 {threshold}회 이상 ({len(high_freq)}주)"
        )
    return None


def _check_monthly_count(df: pd.DataFrame, threshold: int, rule_name: str) -> dict | None:
    """월별 빈도 체크"""
    monthly_counts = df.groupby("month").size()
    high_freq = monthly_counts[monthly_counts >= threshold]
    if len(high_freq) > 0:
        return _make_reason(
            "high_frequency",
            int(monthly_counts.sum()),
            f"월 {threshold}회 이상 ({len(high_freq)}개월)"
        )
    return None


def _check_monthly_total(df: pd.DataFrame, threshold: int, rule_name: str) -> dict | None:
    """월별 총액 체크"""
    monthly_total = df.groupby("month")["금액"].sum()
    high_months = monthly_total[monthly_total >= threshold]
    if len(high_months) > 0:
        return _make_reason(
            "high_monthly",
            len(df),
            f"월 총액 {threshold:,}원 초과 ({len(high_months)}개월)"
        )
    return None


def _check_per_transaction(df: pd.DataFrame, threshold: int, rule_name: str) -> dict | None:
    """건당 고액 체크"""
    expensive = df[df["금액"] >= threshold]
    if len(expensive) > 0:
        return _make_reason(
            "high_amount",
            len(expensive),
            f"건당 {threshold:,}원 이상 ({len(expensive)}건)"
        )
    return None


def _make_reason(type_: str, count: int, message: str) -> dict:
    """reason 딕셔너리 생성"""
    return {"type": type_, "count": count, "message": message}