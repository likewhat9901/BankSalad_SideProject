from pydantic import BaseModel
from typing import Optional, List


# 과소비 규칙 모델
class OverspendingRule(BaseModel):
    id: Optional[int] = None
    name: str
    category_filter: str
    enabled: bool = True
    per_transaction: Optional[int] = None
    weekly_count: Optional[int] = None
    monthly_count: Optional[int] = None
    monthly_total: Optional[int] = None
    time_filter: Optional[List[int]] = None


# 과소비 규칙 전체 수정 모델
class RulesUpdate(BaseModel):
    rules: List[OverspendingRule]