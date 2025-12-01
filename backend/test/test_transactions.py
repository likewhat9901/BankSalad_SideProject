"""거래내역 API 테스트"""
from config import get_parquet_path


class TestTransactionAPI:
    """GET /transactions API 테스트"""

    def test_거래내역_조회_성공(self, client, sample_transactions_df, cleanup_parquet):
        """parquet 생성 후 조회 테스트"""
        # 1. fixture로 받은 DataFrame을 parquet로 저장
        parquet_path = get_parquet_path()
        sample_transactions_df.to_parquet(parquet_path, index=False)

        # 2. API 호출
        response = client.get("/transactions/")

        # 3. 검증
        assert response.status_code == 200
        data = response.json()
        assert "transactions" in data
        assert data["total_count"] > 0