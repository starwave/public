from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql+asyncpg://alma_user:alma_passwd@localhost:5432/alma_db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # API
    api_key: str = ""
    api_host: str = "0.0.0.0"
    api_port: int = 4002
    # cors_origins: str = "http://localhost:4000,http://localhost:4001"
    cors_origins: str = "http://alma-lead.thirdwavesoft.com,http://alma-internal.thirdwavesoft.com"

    # Storage
    storage_backend: str = "local"  # "local" or "s3"
    upload_dir: str = "/mnt/data/alma"

    # S3
    aws_bucket_name: str = ""
    aws_region: str = ""
    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""

    # SMTP
    smtp_host: str = "smtp.zebtoon.ai"
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from_email: str = "noreply@zebtoon.ai"
    attorney_email: str = "attorney@zebtoon.ai"

    class Config:
        env_file = ".env"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


settings = Settings()
