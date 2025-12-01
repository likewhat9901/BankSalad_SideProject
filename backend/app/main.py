from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from app.routers.upload import upload_router
from app.routers.analysis import analysis_router
from app.routers.transactions import transactions_router
from app.routers.stats import stats_router


app = FastAPI(
    title="Banksalad 과소비 분석 API",
    description="뱅크샐러드 데이터 기반 과소비 패턴 분석",
    version="1.0.0"
)

# Flutter 앱에서 호출할 수 있도록 CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 개발 중에는 전체 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(upload_router)
app.include_router(analysis_router)
app.include_router(transactions_router)
app.include_router(stats_router)

# 경로 핸들러
@app.get("/", response_class=HTMLResponse)
def root():
    return """
    <h1>Banksalad API</h1>
    <ul>
        <li><a href="/health">/health</a></li>
        <li><a href="/docs">/docs (Swagger)</a></li>
    </ul>
    """
    

@app.get("/health")
def health_check():
    return {"status": "healthy"}