from pathlib import Path
from .paths import FILE_PATHS


def get_file_path(key: str) -> Path:
    """
    파일 키를 받아 Path 반환
    - 환경/테스트 분기 포인트
    """
    try:
        return FILE_PATHS[key]
    except KeyError:
        raise KeyError(f"정의되지 않은 파일 경로 키: {key}")