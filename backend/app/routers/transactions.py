from fastapi import APIRouter, Query
from typing import Optional

from app.service.transaction_service import get_transactions as fetch_tx


transactions_router = APIRouter(prefix="/transactions", tags=["거래내역"])

@transactions_router.get("/")
def get_transactions(
    limit: int = Query(50, description="조회 개수"),
    category: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
):
    """거래내역 목록 조회"""
    data = fetch_tx(limit, category, start_date, end_date)
    return {"transactions": data}

@transactions_router.get("/search")
def search_transactions(keyword: str):
    """거래내역 검색"""
    return {"results": [...]}