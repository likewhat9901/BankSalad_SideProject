from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from logger import setup_logger

from app.service.data.upload_service import excel_to_parquet
from config import RES_DATA_DIR

logger = setup_logger(__name__) 

upload_router = APIRouter(prefix="/upload", tags=["업로드"])

# 업로드 설정
ALLOWED_EXTENSIONS = {".xlsx", ".xls"}
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB


def validate_excel_file(file: UploadFile, content: bytes) -> None:
    """파일 검증"""
    # 1. 파일명 존재 확인
    if not file.filename:
        raise HTTPException(status_code=400, detail="파일명이 없습니다.")
    
    # 2. 확장자 검증
    ext = "." + file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400, 
            detail=f"허용되지 않는 파일 형식입니다. 허용: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    # 3. 파일 크기 검증
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400, 
            detail=f"파일 크기가 너무 큽니다. 최대: {MAX_FILE_SIZE // (1024*1024)}MB"
        )
    
    # 4. 경로 순회 공격 방지 (../ 등)
    if ".." in file.filename or "/" in file.filename or "\\" in file.filename:
        raise HTTPException(status_code=400, detail="잘못된 파일명입니다.")

@upload_router.post("/excel")
async def upload_excel(
    file: UploadFile = File(...),
):
    """엑셀 파일 업로드 및 변환"""
    # 파일 내용 검증
    content = await file.read()
    validate_excel_file(file, content)
    
    try:
        excel_file_path = RES_DATA_DIR / file.filename
        with open(excel_file_path, "wb") as f:
            f.write(content)
        
        result = excel_to_parquet(excel_file_path)
        logger.info(f"엑셀 파일 변환 완료: {result['message']}")
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"업로드 중 오류 발생: {type(e).__name__}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))