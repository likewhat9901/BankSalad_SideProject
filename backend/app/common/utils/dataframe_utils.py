import pandas as pd


def filter_by_date_range(
    df: pd.DataFrame,
    start_date: str | None,
    end_date: str | None
) -> pd.DataFrame:
    """날짜 범위로 데이터 필터링"""
    # 시작일 필터링
    if start_date:
        df = df[df["거래일시"] >= pd.to_datetime(start_date)]
    # 종료일 필터링
    if end_date:
        df = df[df["거래일시"] <= pd.to_datetime(end_date)]
    return df


def filter_expense_only(df: pd.DataFrame) -> pd.DataFrame:
    """지출 데이터만 필터링 및 금액 절댓값 변환"""
    # 지출 데이터만 필터링
    df = df[df["타입"] == "지출"].copy()
    # 금액 절댓값 변환
    df["금액"] = df["금액"].abs()
    return df


def validate_datetime_column(df: pd.DataFrame) -> None:
    """거래일시 컬럼 데이터 타입 검증"""
    # 거래일시 데이터 타입 검증
    if not pd.api.types.is_datetime64_any_dtype(df["거래일시"]):
        raise ValueError("거래일시 데이터 타입 오류 - parquet 파일을 확인해주세요.")


def enrich_with_time_data(df: pd.DataFrame) -> pd.DataFrame:
    """시간, 요일 데이터 추가"""
    # 시간 데이터 추가
    df["hour"] = df["거래일시"].dt.hour
    # 요일 데이터 추가
    df["day_of_week"] = df["거래일시"].dt.day_name()
    # 일자 데이터 추가
    df["date"] = df["거래일시"].dt.date
    # 데이터프레임 반환
    return df