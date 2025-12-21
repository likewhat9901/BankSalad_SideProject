from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel

from app.service.data.transaction_service import get_transactions as fetch_tx, update_transaction


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
    end_date: str | None = None
):
    """거래내역 목록 조회"""
    data, total_count = fetch_tx(limit, offset, category, start_date, end_date)
    return {
        "transactions": data,
        "total_count": total_count,  # 전체 개수 (더 불러올 데이터가 있는지 판단용)
        "has_more": offset + len(data) < total_count
    }

@transactions_router.put("/{transaction_id}")
def update_transaction_endpoint(transaction_id: int, update_data: TransactionUpdate):
    """거래내역 수정"""
    try:
        result = update_transaction(transaction_id, update_data.dict(exclude_none=True))
        return {"message": "거래내역이 수정되었습니다", "transaction": result}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))