"""API 통합 테스트

모든 API 엔드포인트의 정상 동작을 검증합니다.
실제 데이터가 없어도 최소한 에러 없이 응답하는지 확인합니다.
"""
import pytest
from config import get_parquet_path


class TestHealthAPI:
    """헬스체크 API 테스트"""
    
    def test_health_check(self, client):
        """GET /health 정상 응답"""
        response = client.get("/health")
        
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
    
    def test_root(self, client):
        """GET / 정상 응답"""
        response = client.get("/")
        
        assert response.status_code == 200


class TestTransactionsAPI:
    """거래내역 API 테스트"""
    
    def test_거래내역_조회_데이터없음(self, client):
        """데이터 없을 때 빈 리스트 반환"""
        # parquet 파일이 없으면 빈 응답
        parquet = get_parquet_path()
        if parquet.exists():
            parquet.unlink()
        
        response = client.get("/transactions/")
        
        # 404 또는 빈 리스트 반환 (구현에 따라)
        assert response.status_code in [200, 404]
    
    def test_거래내역_조회_성공(self, client, sample_transactions_df, cleanup_parquet):
        """parquet 있을 때 거래내역 반환"""
        # 샘플 데이터 저장
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/transactions/")
        
        assert response.status_code == 200
        data = response.json()
        assert "transactions" in data
        assert "total_count" in data


class TestAnalysisAPI:
    """분석 API 테스트"""
    
    def test_과소비_패턴_조회(self, client, sample_transactions_df, cleanup_parquet):
        """GET /analysis/patterns 정상 응답"""
        # 샘플 데이터 저장
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/analysis/patterns")
        
        assert response.status_code == 200
        data = response.json()
        assert "count" in data
        assert "patterns" in data
        assert isinstance(data["patterns"], list)
    
    def test_과소비_패턴_연월_필터(self, client, sample_transactions_df, cleanup_parquet):
        """GET /analysis/patterns?year=2025&month=1 필터링"""
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/analysis/patterns?year=2025&month=1")
        
        assert response.status_code == 200
    
    def test_반복소비_패턴_조회(self, client, sample_transactions_df, cleanup_parquet):
        """GET /analysis/recurring 정상 응답"""
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/analysis/recurring")
        
        assert response.status_code == 200
        data = response.json()
        assert "count" in data
        assert "patterns" in data
    
    def test_반복소비_min_count_파라미터(self, client, sample_transactions_df, cleanup_parquet):
        """GET /analysis/recurring?min_count=5 파라미터"""
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/analysis/recurring?min_count=5")
        
        assert response.status_code == 200
    
    def test_시간대_패턴_조회(self, client, sample_transactions_df, cleanup_parquet):
        """GET /analysis/time_based 정상 응답"""
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/analysis/time_based")
        
        assert response.status_code == 200
        data = response.json()
        assert "count" in data
        assert "patterns" in data


class TestPersonalityAPI:
    """소비 성향 API 테스트"""
    
    def test_소비성향_조회(self, client, sample_transactions_df, cleanup_parquet):
        """GET /personality 정상 응답"""
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/personality")
        
        assert response.status_code == 200
        data = response.json()
        assert "type" in data
        assert "name" in data
        assert "scores" in data
    
    def test_소비성향_데이터없으면_기본유형(self, client, cleanup_parquet):
        """데이터 없을 때 기본 유형 반환"""
        # parquet 삭제
        parquet = get_parquet_path()
        if parquet.exists():
            parquet.unlink()
        
        response = client.get("/personality")
        
        assert response.status_code == 200
        data = response.json()
        # 기본 유형이 반환되어야 함
        assert "type" in data


class TestSavingsAPI:
    """절약 기회 API 테스트"""
    
    def test_절약기회_조회(self, client, sample_transactions_df, cleanup_parquet):
        """GET /savings/opportunities 정상 응답"""
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/savings/opportunities")
        
        assert response.status_code == 200
        data = response.json()
        assert "count" in data
        assert "opportunities" in data
        assert isinstance(data["opportunities"], list)
    
    def test_절약기회_연월_필터(self, client, sample_transactions_df, cleanup_parquet):
        """GET /savings/opportunities?year=2025&month=1"""
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/savings/opportunities?year=2025&month=1")
        
        assert response.status_code == 200


class TestStatsAPI:
    """통계 API 테스트"""
    
    def test_월별통계_조회(self, client, sample_transactions_df, cleanup_parquet):
        """GET /stats/monthly 정상 응답"""
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)
        
        response = client.get("/stats/monthly?year=2025&month=1")
        
        assert response.status_code == 200
        data = response.json()
        assert "month" in data
        assert "total_income" in data
        assert "total_expense" in data
        assert "balance" in data
    
    def test_월별통계_필수파라미터_누락(self, client):
        """필수 파라미터 없으면 422 에러"""
        response = client.get("/stats/monthly")
        
        assert response.status_code == 422  # Validation Error
    
    def test_월별통계_잘못된_월(self, client):
        """월이 1-12 범위 밖이면 422 에러"""
        response = client.get("/stats/monthly?year=2025&month=13")
        
        assert response.status_code == 422


class TestUploadAPI:
    """업로드 API 테스트"""
    
    def test_엑셀_업로드_성공(self, client, sample_excel_path, cleanup_parquet):
        """POST /upload/ 엑셀 파일 업로드"""
        with open(sample_excel_path, "rb") as f:
            response = client.post(
                "/upload/excel",
                files={"file": ("test.xlsx", f, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")}
            )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
    
    def test_잘못된_파일형식(self, client):
        """엑셀이 아닌 파일 업로드 시 에러"""
        response = client.post(
            "/upload/excel",
            files={"file": ("test.txt", b"hello world", "text/plain")}
        )
        
        # 400 또는 422 에러
        assert response.status_code in [400, 422]