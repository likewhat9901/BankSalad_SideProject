from fastapi import APIRouter, Query
from typing import Optional

from app.service.transaction_service import get_transactions as fetch_tx

from logger import setup_logger
logger = setup_logger(__name__)

transactions_router = APIRouter(prefix="/transactions", tags=["거래내역"])

@transactions_router.get("/")
def get_transactions(
    limit: int = Query(50, description="조회 개수"),
    offset: int = Query(0, description="건너뛸 개수"),
    category: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
):
    """거래내역 목록 조회"""
    logger.info(f"GET /transactions - limit={limit}, offset={offset}, category={category}")
    data, total_count = fetch_tx(limit, offset, category, start_date, end_date)
    logger.info(f"GET /transactions 완료 - {len(data)}건 반환")
    return {
        "transactions": data,
        "total_count": total_count,  # 전체 개수 (더 불러올 데이터가 있는지 판단용)
        "has_more": offset + len(data) < total_count
    }

@transactions_router.get("/search")
def search_transactions(keyword: str):
    """거래내역 검색"""
    return {"results": [...]}