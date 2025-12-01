from fastapi import APIRouter, Query

from app.service.transaction_service import get_transactions as fetch_tx


transactions_router = APIRouter(prefix="/transactions", tags=["거래내역"])


@transactions_router.get("/")
def get_transactions(
    limit: int = Query(50, description="조회 개수"),
    offset: int = Query(0, description="건너뛸 개수"),
    category: str | None = None,
    start_date: str | None = None,
    end_date: str | None = None
):
    """거래내역 목록 조회"""
    data, total_count = fetch_tx(limit, offset, category, start_date, end_date)
    return {
        "transactions": data,
        "total_count": total_count,  # 전체 개수 (더 불러올 데이터가 있는지 판단용)
        "has_more": offset + len(data) < total_count
    }
