from fastapi import APIRouter, Query
from pydantic import BaseModel

from app.domains.transaction.services import get_transactions as fetch_tx, update_transaction


transactions_router = APIRouter(prefix="/transactions", tags=["거래내역"])

# 수정 요청 모델
class TransactionUpdate(BaseModel):
    description: str | None = None
    amount: int | None = None
    category: str | None = None
    payment_method: str | None = None

@transactions_router.get("/")
def get_transactions(
    limit: int = Query(50, description="조회 개수"),
    offset: int = Query(0, description="건너뛸 개수"),
    category: str | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    merchant: str | None = None,
    payment_method: str | None = None,
    time_range: str | None = None,
    is_weekend: bool | None = None,
    early_month: bool | None = None,
):
    """거래내역 목록 조회"""
    data, total_count = fetch_tx(
        limit, offset, category, start_date, end_date,
        merchant, payment_method, time_range, is_weekend, early_month
    )
    return {
        "transactions": data,
        "total_count": total_count,
        "has_more": offset + len(data) < total_count
    }

@transactions_router.put("/{transaction_id}")
def update_transaction_endpoint(transaction_id: int, update_data: TransactionUpdate):
    """거래내역 수정"""
    # 거래내역 수정
    result = update_transaction(transaction_id, update_data.dict(exclude_none=True))
    # 거래내역 반환
    return {"message": "거래내역이 수정되었습니다", "transaction": result}