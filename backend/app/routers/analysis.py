from fastapi import APIRouter
import pandas as pd
from config import DATA_DIR

analysis_router = APIRouter(prefix="/analysis", tags=["분석"])

@analysis_router.get("/overspending")
def get_overspending_analysis():
    """과소비 패턴 분석"""
    df = pd.read_parquet(DATA_DIR / "transactions.parquet")
    # 분석 로직...
    return {"overspending_categories": [...], "total_overspent": 150000}
