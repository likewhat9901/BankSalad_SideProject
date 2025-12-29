from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from logger import setup_logger

logger = setup_logger(__name__)


def setup_exception_handlers(app):
    """FastAPI 앱에 예외 핸들러 등록"""
    
    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(request: Request, exc: RequestValidationError):
        """요청 파라미터 유효성 검사 실패 (422)"""
        errors = exc.errors()
        logger.warning(f"유효성 검사 실패: {errors}")
        return JSONResponse(
            status_code=422,
            content={
                "detail": "유효성 검사 실패",
                "errors": [
                    {
                        "field": ".".join(str(loc) for loc in e.get("loc", [])),
                        "message": e.get("msg"),
                        "type": e.get("type"),
                    }
                    for e in errors
                ]
            },
        )
    
    @app.exception_handler(ValueError)
    async def value_error_handler(request: Request, exc: ValueError):
        """비즈니스 로직 검증 실패 (400)"""
        logger.warning(f"잘못된 요청: {exc}")
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"detail": str(exc)},
        )
    
    @app.exception_handler(FileNotFoundError)
    async def file_not_found_handler(request: Request, exc: FileNotFoundError):
        """파일/리소스 없음 (404)"""
        logger.warning(f"파일을 찾을 수 없음: {exc}")
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"detail": "요청한 데이터를 찾을 수 없습니다."},
        )
    
    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception):
        """예상치 못한 예외 (500)"""
        logger.error(f"예상치 못한 오류 발생: {exc}", exc_info=True)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": "내부 서버 오류가 발생했습니다."},
        )