## 디렉토리 트리
    backend/
    ├── app/
    │   ├── main.py                         # FastAPI 앱 진입점
    │   ├── routers/        
    │   │   ├── upload.py                   # POST /upload/excel
    │   │   ├── transactions.py             # GET /transactions/
    │   │   ├── analysis.py                 # GET /analysis/overspending
    │   │   └── stats.py                    # GET /stats/monthly
    │   └── service/        
    │       ├── upload_service.py           # 엑셀 → Parquet 변환
    │       ├── transaction_service.py      # 거래내역 조회
    │       ├── overspending_service.py     # 과소비 분석
    │       └── stats_service.py            # 월별 통계
    ├── config.py                           # 경로 설정
    ├── logger.py                           # 로깅 설정
    ├── resData/                            # 원본 엑셀 파일   
    ├── data/                               # 변환된 데이터       
    ├── logs/                               # 로그 파일
    ├── README.md                           # 프로젝트 문서
    ├── requirements.txt                    # 의존성 목록
    └── venv_guide.txt                      # 가상환경 가이드


## API별 흐름
```mermaid
flowchart LR
    A[Flutter] <--> B[main.py]

    B <-->|POST /upload/excel| C[upload.py]
    B <-->|GET /transactions| D[transactions.py]
    B <-->|GET /analysis/overspending| E[analysis.py]
    B <-->|GET /stats/monthly| F[stats.py]

    C --> H[(resData/)]
    C <--> C1[upload_service.py]
    H -.-> C1
    C1 --> G[(data/parquet)]

    D <--> D1[transaction_service.py] <--> G
    E <--> E1[overspending_service.py] <--> G
    F <--> F1[stats_service.py] <--> G
``` 

1. 파일 업로드
    - 요청: Flutter → POST /upload/excel → upload.py → upload_service.py
    - 처리: resData/에 엑셀 저장 → data/parquet으로 변환
    - 응답: { status, message, output_file }

2. 거래내역 조회
    - 요청: Flutter → GET /transactions/ → transactions.py → transaction_service.py
    - 처리: parquet 읽기 → 필터링 → 페이지네이션
    - 응답: { transactions, total_count, has_more }

3. 과소비 분석
    - 요청: Flutter → GET /analysis/overspending → analysis.py → overspending_service.py
    - 처리: parquet 읽기 → 규칙 기반 패턴 분석
    - 응답: { count, patterns }

4. 월별 통계
    - 요청: Flutter → GET /stats/monthly?year=2024&month=12 → stats.py → stats_service.py
    - 처리: parquet 읽기 → 수입/지출 집계
    - 응답: { month, total_income, total_expense, balance, income_breakdown, expense_breakdown }


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