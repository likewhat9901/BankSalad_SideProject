import logging
import os

from datetime import datetime

from config import LOG_DIR

def set_debug_mode(enabled: bool = True) -> None:
    os.environ['DEBUG'] = 'true' if enabled else 'false'

def get_debug_mode() -> bool:
    return os.getenv('DEBUG', 'False').lower() == 'true'

def setup_logger(name: str = __name__) -> logging.Logger:
    """
    Description: 로거를 설정하고 반환합니다.
    
    Parameters:
        name: 로거 이름 (보통 __name__ 사용)
    
    Returns: 설정된 Logger 객체
    """
    # 디버그 설정 (개발자 용, 실제 배포 시 False로 설정)
    set_debug_mode(True)
    
    # 디버그 모드 확인 (환경 변수만 확인)
    debug = get_debug_mode()

    # 로그 레벨 설정
    log_level = logging.DEBUG if debug else logging.INFO

    # 로그 디렉토리 생성
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    
    # 로그 파일명 생성 (타임스탬프 포함)
    log_filename = LOG_DIR / f'log_{datetime.now().strftime("%Y%m%d")}.log'

    # 파일이 새로 생성되는지 확인
    is_new_file = not log_filename.exists()
    
    # 로거 생성
    logger = logging.getLogger(name)
    logger.setLevel(log_level)
    
    # 기존 핸들러가 있으면 제거 (중복 방지)
    if logger.handlers:
        logger.handlers.clear()
    
    # 포맷 설정
    formatter = logging.Formatter(
        '%(asctime)s.%(msecs)03d [%(levelname)s] %(name)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # 파일 핸들러 (날짜별, append 모드)
    file_handler = logging.FileHandler(log_filename, encoding='utf-8', mode='a')
    file_handler.setLevel(log_level)
    file_handler.setFormatter(formatter)
    
    # 콘솔 핸들러
    console_handler = logging.StreamHandler()
    console_handler.setLevel(log_level)
    console_handler.setFormatter(formatter)
    
    # 핸들러 추가
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    # 로그 파일 생성 정보 기록
    if is_new_file:
        logger.info(f"로그 파일이 생성되었습니다: {log_filename}")

    # 디버그 모드 확인
    if debug:
        logger.debug("디버그 모드가 활성화되었습니다. 로그 레벨: DEBUG")
    
    return logger