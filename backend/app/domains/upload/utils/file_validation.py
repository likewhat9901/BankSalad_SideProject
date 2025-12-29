from fastapi import UploadFile, HTTPException

ALLOWED_EXTENSIONS = {".xlsx", ".xls"}
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB


def validate_excel_file(file: UploadFile, content: bytes) -> None:
    """엑셀 파일 검증"""
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
    
    # 4. 경로 순회 공격 방지
    if ".." in file.filename or "/" in file.filename or "\\" in file.filename:
        raise HTTPException(status_code=400, detail="잘못된 파일명입니다.")