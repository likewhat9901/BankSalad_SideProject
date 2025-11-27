from fastapi import APIRouter, UploadFile, File, HTTPException
from excel_to_parquet import convert_excel_to_parquet
from config import RES_DATA_DIR
from logger import setup_logger

logger = setup_logger(__name__) # 로깅 설정

upload_router = APIRouter(prefix="/upload", tags=["업로드"])

@upload_router.post("/excel")
async def upload_excel(file: UploadFile = File(...)):
    """엑셀 파일 업로드 및 변환"""
    try:
        excel_file_path = RES_DATA_DIR / file.filename
        with open(excel_file_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        result = convert_excel_to_parquet(excel_file_path)
        return result
    except Exception as e:
        logger.error(f"업로드 실패: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))