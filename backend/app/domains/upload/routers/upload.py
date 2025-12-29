from fastapi import APIRouter, UploadFile, File

from logger import setup_logger
from app.domains.upload.services.excel_service import process_excel_upload

logger = setup_logger(__name__)

upload_router = APIRouter(prefix="/upload", tags=["업로드"])


@upload_router.post("/excel")
async def upload_excel(file: UploadFile = File(...)):
    """엑셀 파일 업로드 및 변환"""

    # 엑셀 파일 읽기
    content = await file.read()
    
    # 엑셀 파일 업로드 및 변환
    result = process_excel_upload(file, content)
    logger.info(f"엑셀 파일 변환 완료: {result['message']}")

    return result