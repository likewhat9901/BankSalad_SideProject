import os

# 환경변수에서 이메일 설정 로드
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")      # Gmail SMTP 서버 주소
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))            # Gmail SMTP 서버 포트
SMTP_USER = os.getenv("SMTP_USER", "")                    # 발신자 이메일
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")            # 앱 비밀번호
INQUIRY_RECIPIENT = os.getenv("INQUIRY_RECIPIENT", "")    # 문의 받을 이메일