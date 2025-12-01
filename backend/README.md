## 주요 디렉토리 및 파일
    - resData/    : 원본 Excel 파일
    - data/       : 변환된 Parquet 파일
    - parse/      : 필터링 결과
    - logs/       : 로그 파일
    - config.py   : 공통 설정값


## 필요한 추가 모듈 (표준 라이브러리 외)
    - pandas    : 데이터 처리
    - openpyxl  : 엑셀 파일 읽기
    - pyarrow   : Parquet 파일 처리


## 엑셀 파일 형식
    필수 컬럼: 날짜(ms timestamp), 시간(문자열), 대분류, 금액


## API별 흐름
1. 파일 업로드
    Flutter → POST /upload/excel → upload.py → upload_service.py
    - 엑셀 파일을 resData/에 저장
    - parquet 파일로 변환 후, data/에 저장

2. 거래내역 조회
    Flutter → GET /transactions/ → transactions.py → transaction_service.py
    - Parquet 파일 읽기
    - 카테고리/날짜 필터링
    - 페이지네이션
    - { transactions, total_count, has_more } 반환

3. 과소비 분석 (TODO)
    Flutter → GET /analysis/overspending → analysis.py (미완성)


## 서버 실행
    cd backend
    .\venv\Scripts\activate
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

    Swagger UI: http://localhost:8000/docs


## TEST 방법
    cd backend
    .\venv\Scripts\activate

    # 전체 테스트 실행
    pytest

    # 상세 출력
    pytest -v

    # 특정 파일만 실행
    pytest test/test_upload.py