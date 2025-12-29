import pandas as pd
from config import get_parquet_path
from logger import setup_logger

logger = setup_logger(__name__)


def load_transactions() -> pd.DataFrame:
    """거래내역 parquet 파일 로드
    
    Returns:
        DataFrame (파일 없으면 빈 DataFrame)
    """
    # Parquet 파일 경로 생성
    parquet_path = get_parquet_path()
    
    # Parquet 파일 존재 확인
    if not parquet_path.exists():
        # 파일이 없으면 빈 DataFrame 반환
        logger.warning(f"파일 없음: {parquet_path}")
        return pd.DataFrame()
    
    # Parquet 파일 로드
    return pd.read_parquet(parquet_path)


def save_transactions(df: pd.DataFrame) -> None:
    """거래내역 parquet 파일 저장
    
    Args:
        df: 저장할 DataFrame
    """
    # Parquet 파일 경로 생성
    parquet_path = get_parquet_path()
    # Parquet 파일로 저장
    df.to_parquet(parquet_path, index=False)
    # 저장된 파일 경로 반환
    logger.info(f"거래내역 저장 완료: {parquet_path}")


def find_transaction_by_id(df: pd.DataFrame, transaction_id: int) -> tuple[int, pd.Series]:
    """ID로 거래내역 찾기
    
    Args:
        df: 검색할 DataFrame
        transaction_id: 거래내역 ID
    
    Returns:
        (row_index, row_data) 튜플
    
    Raises:
        ValueError: 거래내역을 찾을 수 없는 경우
    """
    # ID로 거래내역 찾기
    mask = df['id'] == transaction_id
    # ID로 거래내역 개수 카운트
    matching_count = mask.sum()
    
    # ID로 거래내역이 없으면 예외 발생
    if matching_count == 0:
        # 거래내역을 찾을 수 없습니다: ID {transaction_id}
        raise ValueError(f"거래내역을 찾을 수 없습니다: ID {transaction_id}")
    
    # ID로 거래내역이 중복되면 경고 메시지 출력
    if matching_count > 1:
        # 중복된 ID 발견: {transaction_id} ({matching_count}개 행)
        logger.warning(f"중복된 ID 발견: {transaction_id} ({matching_count}개 행)")
    
    # ID로 거래내역 인덱스 찾기
    row_index = df[mask].index[0]
    # ID로 거래내역 데이터 반환
    return row_index, df.loc[row_index]


def filter_transactions(
    df: pd.DataFrame,
    category: str | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    merchant: str | None = None,
    payment_method: str | None = None,
    time_range: str | None = None,
    is_weekend: bool | None = None,
    early_month: bool | None = None,
) -> pd.DataFrame:
    """거래내역 필터링"""
    # 카테고리 필터링
    if category:
        df = df[df["대분류"] == category]
    # 시작일 필터링
    if start_date:
        df = df[df["거래일시"] >= pd.to_datetime(start_date)]
    # 종료일 필터링
    if end_date:
        df = df[df["거래일시"] <= pd.to_datetime(end_date)]
    
    # 👇 추가 필터들
    # 상호명 필터링
    if merchant:
        df = df[df["내용"].str.contains(merchant, na=False)]
    
    # 결제수단 필터링
    if payment_method:
        df = df[df["결제수단"] == payment_method]
    
    # 시간대 필터링 (ex: "18:00-22:00")
    if time_range:
        parts = time_range.split("-")
        if len(parts) == 2:
            start_hour = int(parts[0].split(":")[0])
            end_hour = int(parts[1].split(":")[0])
            hours = df["거래일시"].dt.hour
            if start_hour < end_hour:
                df = df[(hours >= start_hour) & (hours < end_hour)]
            else:  # 야간 (22:00-06:00)
                df = df[(hours >= start_hour) | (hours < end_hour)]
    
    # 주말 필터링
    if is_weekend:
        df = df[df["거래일시"].dt.dayofweek >= 5]  # 5=토, 6=일
    
    # 월 초 필터링 (1~5일)
    if early_month:
        df = df[df["거래일시"].dt.day <= 5]
    
    return df


def paginate_transactions(
    df: pd.DataFrame,
    offset: int,
    limit: int,
    sort_by: str = "거래일시",
    ascending: bool = False
) -> pd.DataFrame:
    """거래내역 정렬 및 페이지네이션
    
    Args:
        df: 원본 DataFrame
        offset: 건너뛸 개수
        limit: 가져올 개수
        sort_by: 정렬 기준 컬럼
        ascending: 오름차순 여부
    
    Returns:
        페이지네이션된 DataFrame
    """
    # 정렬된 DataFrame 생성
    df_sorted = df.sort_values(sort_by, ascending=ascending)
    return df_sorted.iloc[offset:offset + limit].copy()