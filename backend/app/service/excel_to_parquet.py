import io
import sys
from pathlib import Path

import pandas as pd

from logger import setup_logger, get_debug_mode
from config import RES_DATA_DIR, DATA_DIR

logger = setup_logger(__name__) # 로깅 설정


# --- 설정값 ---


def convert_excel_to_parquet(
    excel_file_path: Path, 
    sheet_name: int = 1,
) -> dict:
    """엑셀 파일을 Parquet로 변환
    
    Args:
        excel_file_path: 변환할 엑셀 파일 경로
        sheet_name: 읽을 시트 번호 (기본값: 1)
        verify_output: 저장 후 파일 검증 여부
    """
    logger.info(f"엑셀 파일 '{excel_file_path.name}' 변환 시작")
    output_parquet_file = DATA_DIR / f"{excel_file_path.stem}.parquet"
    
    # --- 1단계: 엑셀 파일 불러오기 ---
    try:
        df = pd.read_excel(excel_file_path, sheet_name=sheet_name, index_col=None)
    except FileNotFoundError:
        logger.error(f"파일을 찾을 수 없음: '{excel_file_path}'")
        raise
    except Exception as e:
        logger.error(f"엑셀 파일 읽기 오류: {e}")
        raise
    logger.info(f"데이터 로드 완료: {len(df)}행 x {len(df.columns)}열")

    # 원본 데이터 가공
    df['거래일시'] = pd.to_datetime(df['날짜'], unit='ms') + pd.to_timedelta(df['시간'].astype(str))
    other_cols = [col for col in df.columns if col not in ['거래일시', '날짜', '시간']]
    df = df[['거래일시'] + other_cols]

    # 가공된 데이터 미리보기
    logger.debug(f"가공 후 데이터:\n{df.head()}")

    logger.debug("Parquet 저장 전 데이터 컬럼 정보")
    # df.info()의 출력을 문자열로 캡처
    with io.StringIO() as buf:
        df.info(buf=buf)
        info_str = buf.getvalue()
        logger.debug(f"\n{info_str}")

    # --- 3단계: Parquet 파일로 저장하기 ---
    # 출력 디렉토리 생성
    output_parquet_file.parent.mkdir(parents=True, exist_ok=True)

    try:
        df.to_parquet(output_parquet_file, index=False)
        file_size_mb = output_parquet_file.stat().st_size / (1024 * 1024)
        logger.info(f"Parquet 파일 저장 완료: '{output_parquet_file}' ({file_size_mb:.2f} MB)")
    except Exception as e:
        logger.error(f"Parquet 저장 오류: {e}")
        raise

    # 선택적 검증
    if get_debug_mode():
        preview_df = pd.read_parquet(output_parquet_file)   # 저장된 파일 다시 읽기
        logger.debug(f"저장 검증:\n{preview_df.head().to_string()}")    # 상위 5행 출력

    return {
        "status": "success",
        "message": f"'{excel_file_path.name}' 변환 완료",
        "output_file": str(output_parquet_file)
    }

# 독립 실행용 (테스트 용)
# venv 활성화 후, bankend 디렉토리로 이동, python -m app.service.excel_to_parquet
if __name__ == "__main__":
    logger.info("엑셀 파일 변환 테스트 시작...")

    test_excel_file_name = 'test_excel_file.xlsx'
    result = convert_excel_to_parquet(RES_DATA_DIR / test_excel_file_name)
    logger.info(f"결과: {result}")
    
    sys.exit(0)