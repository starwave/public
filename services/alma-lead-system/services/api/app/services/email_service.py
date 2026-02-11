import logging
from pathlib import Path

import aiosmtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from jinja2 import Environment, FileSystemLoader

from app.config import settings

logger = logging.getLogger(__name__)

_template_dir = Path(__file__).resolve().parent.parent / "templates"
_jinja_env = Environment(loader=FileSystemLoader(str(_template_dir)), autoescape=True)


async def _send_email(to: str, subject: str, html_body: str) -> None:
    msg = MIMEMultipart("alternative")
    msg["From"] = settings.smtp_from_email
    msg["To"] = to
    msg["Subject"] = subject
    msg.attach(MIMEText(html_body, "html"))

    try:
        await aiosmtplib.send(
            msg,
            hostname=settings.smtp_host,
            port=settings.smtp_port,
            start_tls=True,
            username=settings.smtp_username,
            password=settings.smtp_password,
        )
        logger.info("Email sent to %s", to)
    except Exception:
        logger.exception("Failed to send email to %s", to)


async def send_prospect_confirmation(
    email: str, first_name: str, last_name: str
) -> None:
    template = _jinja_env.get_template("prospect_email.html")
    html = template.render(first_name=first_name, last_name=last_name)
    await _send_email(email, "Thank you for your submission – Alma", html)


async def send_attorney_notification(
    first_name: str, last_name: str, email: str
) -> None:
    template = _jinja_env.get_template("attorney_email.html")
    html = template.render(first_name=first_name, last_name=last_name, email=email)
    await _send_email(
        settings.attorney_email,
        f"New Lead: {first_name} {last_name}",
        html,
    )
