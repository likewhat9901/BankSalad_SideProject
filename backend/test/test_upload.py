"""업로드 서비스 테스트"""
from app.service.upload_service import excel_to_parquet
from config import get_parquet_path

class TestUploadService:
    """upload_service.py 테스트"""

    def test_엑셀_파켓_변환_성공(self, sample_excel_path, cleanup_parquet):
        """엑셀 → parquet 변환 테스트"""
        result = excel_to_parquet(sample_excel_path)
        
        assert result["status"] == "success"                # 반환값 검증
        assert get_parquet_path().exists()       # 파일 존재 검증
