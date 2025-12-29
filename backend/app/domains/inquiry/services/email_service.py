import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from logger import setup_logger
from app.common.config.email_config import (
    SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, INQUIRY_RECIPIENT
)

logger = setup_logger(__name__)


def send_inquiry_email(subject: str, body: str, sender_email: str | None = None) -> bool:
    """문의 이메일 발송"""
    
    if not all([SMTP_USER, SMTP_PASSWORD, INQUIRY_RECIPIENT]):
        logger.error("이메일 설정이 완료되지 않았습니다")
        raise ValueError("이메일 설정이 완료되지 않았습니다")
    
    try:
        # 이메일 메시지 생성
        msg = MIMEMultipart()
        msg['From'] = SMTP_USER
        msg['To'] = INQUIRY_RECIPIENT
        msg['Subject'] = f"[뱅크드레싱 문의] {subject}"
        
        # 본문 구성
        email_body = f"""
새로운 문의가 접수되었습니다.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 발신자: {sender_email or '미입력'}
📝 제목: {subject}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{body}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
이 메일은 뱅크드레싱 앱에서 자동 발송되었습니다.
"""
        msg.attach(MIMEText(email_body, 'plain', 'utf-8'))
        
        # SMTP 연결 및 발송
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(msg)
        
        logger.info(f"문의 이메일 발송 완료: {subject}")
        return True
        
    except Exception as e:
        logger.error(f"이메일 발송 실패: {e}")
        raise