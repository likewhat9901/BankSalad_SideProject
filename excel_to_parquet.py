import io
import os
import sys

import pandas as pd

from logger import setup_logger

logger = setup_logger(__name__)

# --- 설정값 ---
input_excel_file = 'file/2024-11-12~2025-11-12.xlsx' 
output_parquet_file = 'data/가계부_데이터_저장용.parquet'
sheet_name_to_read = 1

# --- 1단계: 엑셀 파일 불러오기 ---
try:
    df = pd.read_excel(
        input_excel_file,
        sheet_name=sheet_name_to_read,
        index_col=None
    )
    logger.info(f"엑셀 파일 '{input_excel_file}'을 성공적으로 불러왔습니다.")
    
except FileNotFoundError:
    logger.error(f"지정된 엑셀 파일 '{input_excel_file}'을 찾을 수 없습니다.")
    sys.exit(1)
except Exception as e:
    logger.error(f"엑셀 파일 읽기 중 오류 발생: {str(e)}")
    sys.exit(1)

# --- 2단계: DataFrame 확인 및 처리 ---
logger.debug("불러온 데이터 미리보기")
logger.debug(f"\n{df.head()}")
logger.info(f"데이터 크기: {len(df)} 행, {len(df.columns)} 열")

logger.debug("Parquet 저장 전 데이터 컬럼 정보")
# df.info()의 출력을 문자열로 캡처
with io.StringIO() as buf:
    df.info(buf=buf)
    info_str = buf.getvalue()
    logger.debug(f"\n{info_str}")

# --- 3단계: Parquet 파일로 저장하기 ---
# 출력 디렉토리 생성
output_dir = os.path.dirname(output_parquet_file)
if output_dir:
    os.makedirs(output_dir, exist_ok=True)

try:
    df.to_parquet(output_parquet_file, index=False)
    file_size_mb = os.path.getsize(output_parquet_file) / (1024 * 1024)
    logger.info(f"데이터를 '{output_parquet_file}' 파일로 성공적으로 저장했습니다.")
    logger.info(f"저장된 파일 크기: {file_size_mb:.2f} MB")
except Exception as e:
    logger.error(f"Parquet 파일 저장 중 오류 발생: {str(e)}")
    sys.exit(1)