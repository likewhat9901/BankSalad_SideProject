from fastapi import APIRouter
from pydantic import BaseModel, EmailStr

from app.domains.inquiry.services.email_service import send_inquiry_email


inquiry_router = APIRouter(prefix="/inquiry", tags=["문의"])


class InquiryRequest(BaseModel):
    subject: str
    body: str
    email: str | None = None  # 발신자 이메일 (선택)


@inquiry_router.post("/")
def submit_inquiry(request: InquiryRequest):
    """문의 제출"""
    send_inquiry_email(
        subject=request.subject,
        body=request.body,
        sender_email=request.email
    )
    return {"status": "success", "message": "문의가 접수되었습니다"}