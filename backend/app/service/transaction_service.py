import pandas as pd
from config import get_parquet_path

from logger import setup_logger


logger = setup_logger(__name__)

def get_transactions(
    limit: int,
    offset: int,
    category: str | None,
    start_date: str | None,
    end_date: str | None
) -> tuple[list[dict], int]:
    """거래내역 조회"""
    parquet_path = get_parquet_path()

    logger.info(f"거래내역 조회 요청 - limit: {limit}, offset: {offset}, category: {category}, start_date: {start_date}, end_date: {end_date}")
    
    if not parquet_path.exists():
        logger.warning(f"파일 없음: {parquet_path} - 빈 배열 반환")
        return [], 0

    try:
        df = pd.read_parquet(parquet_path)
        
        if category:
            df = df[df["대분류"] == category]
        if start_date:
            df = df[df["거래일시"] >= pd.to_datetime(start_date)]
        if end_date:
            df = df[df["거래일시"] <= pd.to_datetime(end_date)]
        
        total_count = len(df)  # 필터 후 전체 개수

        # 정렬 후 페이지네이션
        df_sorted = df.sort_values("거래일시", ascending=False)
        df_filtered = df_sorted.iloc[offset:offset + limit].copy()

        # 
        result = []
        for _, row in df_filtered.iterrows():
            row_dict = row.to_dict()
            if '거래일시' in row_dict:
                row_dict['거래일시'] = pd.to_datetime(row_dict['거래일시']).strftime("%Y-%m-%d %H:%M:%S")
            result.append(row_dict)

        logger.info(f"거래내역 조회 완료 - 전체: {total_count}건, 반환: {len(result)}건")
        return result, total_count

    except Exception as e:
        logger.error(f"거래내역 조회 실패: {e}")
        raise

def update_transaction(transaction_id: int, update_data: dict) -> dict:
    """거래내역 수정"""
    parquet_path = get_parquet_path()
    
    if not parquet_path.exists():
        raise ValueError("거래내역 파일이 없습니다")
    
    try:
        df = pd.read_parquet(parquet_path)
        
        # ID 컬럼으로 거래내역 찾기
        mask = df['id'] == transaction_id
        matching_count = mask.sum()
        
        # 매칭되는 행이 없으면 에러
        if matching_count == 0:
            raise ValueError(f"거래내역을 찾을 수 없습니다: ID {transaction_id}")
        
        # 매칭되는 행이 여러 개면 첫 번째 행만 수정
        if matching_count > 1:
            logger.warning(f"중복된 ID 발견: {transaction_id} ({matching_count}개 행)")
            # 첫 번째 매칭되는 행만 수정
            row_index = df[mask].index[0]
        else:
            row_index = df[mask].index[0]
        
        # 수정할 필드 매핑
        field_mapping = {
            'description': '내용',
            'amount': '금액',
            'category': '대분류',
            'payment_method': '결제수단',
        }
        
        # 데이터 수정
        for key, value in update_data.items():
            if key in field_mapping and value is not None:
                df.loc[row_index, field_mapping[key]] = value
        
        # 파일 저장
        df.to_parquet(parquet_path, index=False)
        
        logger.info(f"거래내역 수정 완료: ID {transaction_id}")
        
        # 수정된 거래내역 반환
        updated_row = df.loc[row_index].to_dict()
        if '거래일시' in updated_row:
            updated_row['거래일시'] = pd.to_datetime(updated_row['거래일시']).strftime("%Y-%m-%d %H:%M:%S")
        
        return updated_row
        
    except Exception as e:
        logger.error(f"거래내역 수정 실패: {e}")
        raise