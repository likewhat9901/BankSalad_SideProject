import pandas as pd
import os
from datetime import time

# Parquet 파일 읽기
parquet_file = 'data/가계부_데이터_저장용.parquet'
print(f"Parquet 파일 읽는 중: {parquet_file}")

try:
    df = pd.read_parquet(parquet_file)
    print(f"원본 데이터 행 수: {len(df)}")
    print(f"컬럼: {df.columns.tolist()}")
except Exception as e:
    print(f"오류 발생: {str(e)}")
    exit(1)

# 컬럼명 정의
date_col = '날짜'
time_col = '시간'
amount_col = '금액'
main_category_col = '대분류'

# 필수 컬럼 존재 확인
required_cols = [date_col, time_col, amount_col, main_category_col]
missing_cols = [col for col in required_cols if col not in df.columns]
if missing_cols:
    print(f"오류: 필수 컬럼이 없습니다: {missing_cols}")
    exit(1)

# 시간(hour) 추출
# 시간 컬럼이 datetime.time 객체인 경우
if isinstance(df[time_col].iloc[0], time):
    df['hour'] = df[time_col].apply(lambda x: x.hour if isinstance(x, time) else None)
elif pd.api.types.is_datetime64_any_dtype(df[time_col]):
    df['hour'] = df[time_col].dt.hour
else:
    # 문자열이나 다른 형태인 경우 datetime으로 변환 시도
    df['hour'] = pd.to_datetime(df[time_col], errors='coerce').dt.hour
    # 변환 실패한 경우, 날짜 컬럼에서 시간 추출
    if df['hour'].isna().any():
        df['hour'] = df[date_col].dt.hour

# 조건 정의
overpriced = df[amount_col] >= 50000
time_condition = (df['hour'] >= 18) | (df['hour'] < 6)
category = df[main_category_col].astype(str).str.contains('식사', na=False, case=False)

# 금액 컬럼 처리 (음수인 경우 절댓값으로 변환)
df[amount_col] = df[amount_col].abs()

# 최종 조건: 대분류가 '식사' AND (시간 조건 OR 금액 조건)
full_condition = category & (time_condition | overpriced)

# 필터링된 데이터
result_df = df[full_condition].copy()

if len(result_df) > 0:
    # parse 폴더 생성
    os.makedirs('parse', exist_ok=True)
    
    # Parquet로 저장
    output_file = 'parse/식사_필터링_결과.parquet'
    try:
        result_df.to_parquet(output_file, index=False, engine='pyarrow')
        print(f"\n결과를 '{output_file}'에 저장했습니다.")
    except Exception as e:
        print(f"Parquet 저장 오류 (pyarrow 미설치 가능): {str(e)}")
        try:
            result_df.to_parquet(output_file, index=False, engine='fastparquet')
            print(f"Parquet 파일 저장 완료 (fastparquet 사용): {output_file}")
        except Exception as e2:
            print(f"Parquet 저장 실패: {str(e2)}")
            exit(1)
else:
    print("조건에 맞는 데이터가 없습니다.")

