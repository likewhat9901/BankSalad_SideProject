import pandas as pd
from logger import setup_logger

from app.domains.transaction.repository import (
    load_transactions,
    save_transactions,
    find_transaction_by_id,
    filter_transactions,
    paginate_transactions,
)

logger = setup_logger(__name__)


def get_transactions(
    limit: int,
    offset: int,
    category: str | None,
    start_date: str | None,
    end_date: str | None,
    merchant: str | None = None,
    payment_method: str | None = None,
    time_range: str | None = None,
    is_weekend: bool | None = None,
    early_month: bool | None = None,
) -> tuple[list[dict], int]:
    """거래내역 조회"""
    logger.info(f"거래내역 조회 요청 - limit: {limit}, offset: {offset}, category: {category}, start_date: {start_date}, end_date: {end_date}, merchant: {merchant}, payment_method: {payment_method}, time_range: {time_range}, is_weekend: {is_weekend}, early_month: {early_month}")
    
    # 거래내역 조회
    df = load_transactions()
    # 거래내역이 없으면 빈 리스트 반환
    if df.empty:
        return [], 0
    
    # 거래내역 필터링
    df = filter_transactions(
        df, category, start_date, end_date,
        merchant, payment_method, time_range, is_weekend, early_month
    )
    # 거래내역 전체 개수
    total_count = len(df)
    # 거래내역 페이지 조회
    df_page = paginate_transactions(df, offset, limit)
    # 거래내역 포맷팅
    result = _format_transactions(df_page)
    logger.info(f"거래내역 조회 완료 - 전체: {total_count}건, 반환: {len(result)}건")
    return result, total_count


def update_transaction(transaction_id: int, update_data: dict) -> dict:
    """거래내역 수정""" 
    # 거래내역 조회
    df = load_transactions()
    # 거래내역이 없으면 예외 발생
    if df.empty:
        raise ValueError("거래내역 파일이 없습니다")
    
    # 거래내역 조회
    row_index, _ = find_transaction_by_id(df, transaction_id)
    # 거래내역 필드 업데이트
    df = _apply_field_updates(df, row_index, update_data)
    # 거래내역 저장
    save_transactions(df)
    # 거래내역 포맷팅
    logger.info(f"거래내역 수정 완료: ID {transaction_id}")
    # 거래내역 반환
    return _format_transaction(df.loc[row_index])

# ----------------------------------------------------------------
# private functions (비즈니스 로직)
# ----------------------------------------------------------------
def _format_transactions(df: pd.DataFrame) -> list[dict]:
    """DataFrame을 딕셔너리 리스트로 변환"""
    return [_format_transaction(row) for _, row in df.iterrows()]


def _format_transaction(row: pd.Series) -> dict:
    """Series를 딕셔너리로 변환 (날짜 포맷팅 포함)"""

    # Series를 딕셔너리로 변환
    row_dict = row.to_dict()
    # 거래일시 포맷팅
    if '거래일시' in row_dict:
        row_dict['거래일시'] = pd.to_datetime(row_dict['거래일시']).strftime("%Y-%m-%d %H:%M:%S")
    
    # 딕셔너리 반환
    return row_dict


def _apply_field_updates(df: pd.DataFrame, row_index: int, update_data: dict) -> pd.DataFrame:
    """필드 업데이트 적용"""

    # 필드 매핑
    field_mapping = {
        'description': '내용',
        'amount': '금액',
        'category': '대분류',
        'payment_method': '결제수단',
    }
    
    # 필드 업데이트 적용
    for key, value in update_data.items():
        if key in field_mapping and value is not None:
            df.loc[row_index, field_mapping[key]] = value
    
    # DataFrame 반환
    return df