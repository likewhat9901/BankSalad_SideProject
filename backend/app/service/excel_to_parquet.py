import io
import sys
from pathlib import Path

import pandas as pd

from logger import setup_logger
from config import RES_DATA_DIR, DATA_DIR

logger = setup_logger(__name__) # 로깅 설정


# --- 설정값 ---
sheet_name_to_read = 1


def convert_excel_to_parquet(excel_file_path: Path) -> dict:
    """엑셀 파일을 Parquet로 변환"""
    logger.info(f"엑셀 파일 '{excel_file_path.name}'을 변환 중...")

    # 출력 파일명 동적 생성 (입력 파일명 기반)
    output_parquet_file = DATA_DIR / f"{excel_file_path.stem}.parquet"
    
    # --- 1단계: 엑셀 파일 불러오기 ---
    try:
        df = pd.read_excel(
            excel_file_path,
            sheet_name=sheet_name_to_read,
            index_col=None
        )
        logger.info(f"엑셀 파일 '{excel_file_path.name}'을 성공적으로 불러왔습니다.")
        
    except FileNotFoundError:
        logger.error(f"지정된 엑셀 파일 '{excel_file_path}'을 찾을 수 없습니다.")
        raise
    except Exception as e:
        logger.error(f"엑셀 파일 읽기 중 오류 발생: {str(e)}")
        raise

    # --- 2단계: DataFrame 확인 및 처리 ---
    logger.debug("불러온 데이터 미리보기")
    logger.debug(f"\n{df.head()}")
    logger.info(f"데이터 크기: {len(df)} 행, {len(df.columns)} 열")

    # 원본 데이터 가공
    logger.debug("거래일시 컬럼 생성 시작")
    date = pd.to_datetime(df['날짜'], unit='ms')
    time = pd.to_timedelta(df['시간'].astype(str))
    df['거래일시'] = date + time
    other_cols = [col for col in df.columns if col not in ['거래일시', '날짜', '시간']]
    new_col_order = ['거래일시'] + other_cols
    df = df[new_col_order]
    logger.debug("거래일시 컬럼 생성 완료")

    # 가공된 데이터 미리보기
    logger.debug("가공된 데이터 미리보기")
    logger.debug(f"\n{df.head()}")

    logger.debug("Parquet 저장 전 데이터 컬럼 정보")
    # df.info()의 출력을 문자열로 캡처
    with io.StringIO() as buf:
        df.info(buf=buf)
        info_str = buf.getvalue()
        logger.debug(f"\n{info_str}")

    # --- 3단계: Parquet 파일로 저장하기 ---
    # 출력 디렉토리 생성
    output_dir = output_parquet_file.parent
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        df.to_parquet(output_parquet_file, index=False)
        file_size_mb = output_parquet_file.stat().st_size / (1024 * 1024)
        logger.info(f"데이터를 '{output_parquet_file}' 파일로 성공적으로 저장했습니다.")
        logger.info(f"저장된 파일 크기: {file_size_mb:.2f} MB")
    except Exception as e:
        logger.error(f"Parquet 파일 저장 중 오류 발생: {str(e)}")
        raise

    try:
        preview_df = pd.read_parquet(output_parquet_file)
        logger.debug("--- Parquet 파일 저장 내용 미리보기 (상위 5개 행) ---")
        logger.debug(f"\n{preview_df.head().to_string()}")
        logger.debug("--------------------------------------------------")
    except Exception as e:
        logger.error(f"Parquet 파일 읽기 중 오류 발생: {str(e)}")
        raise

    return {
        "status": "success",
        "message": f"엑셀 파일 '{excel_file_path.name}'을 성공적으로 변환했습니다.",
        "output_file": str(output_parquet_file)
    }

# 독립 실행용 (테스트 용)
if __name__ == "__main__":
    logger.info("엑셀 파일 변환 테스트 시작...")

    test_excel_file_name = 'test_excel_file.xlsx'
    test_excel_file_path = RES_DATA_DIR / test_excel_file_name
    result = convert_excel_to_parquet(test_excel_file_path)
    logger.info(f"엑셀 파일 변환 결과: {result}")
    logger.info("엑셀 파일 변환 테스트 완료")
    
    sys.exit(0)