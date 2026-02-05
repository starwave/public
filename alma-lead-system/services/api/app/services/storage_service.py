import os
import uuid
from abc import ABC, abstractmethod

import aiofiles
import boto3
from fastapi import UploadFile

from app.config import settings

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_CONTENT_TYPES = {"application/pdf"}


class StorageBackend(ABC):
    @abstractmethod
    async def save(self, file: UploadFile, filename: str) -> str:
        ...

    @abstractmethod
    def get_url(self, path: str) -> str:
        ...


class LocalStorage(StorageBackend):
    def __init__(self, upload_dir: str):
        self.upload_dir = upload_dir
        os.makedirs(upload_dir, exist_ok=True)

    async def save(self, file: UploadFile, filename: str) -> str:
        filepath = os.path.join(self.upload_dir, filename)
        async with aiofiles.open(filepath, "wb") as f:
            while chunk := await file.read(8192):
                await f.write(chunk)
        return filepath

    def get_url(self, path: str) -> str:
        return path


class S3Storage(StorageBackend):
    def __init__(self):
        self.bucket = settings.aws_bucket_name
        self.region = settings.aws_region
        self.client = boto3.client(
            "s3",
            region_name=self.region,
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
        )

    async def save(self, file: UploadFile, filename: str) -> str:
        key = f"resumes/{filename}"
        contents = await file.read()
        self.client.put_object(
            Bucket=self.bucket,
            Key=key,
            Body=contents,
            ContentType=file.content_type or "application/pdf",
        )
        return key

    def get_url(self, path: str) -> str:
        return self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": self.bucket, "Key": path},
            ExpiresIn=3600,
        )


def _create_backend() -> StorageBackend:
    if settings.storage_backend == "s3":
        return S3Storage()
    return LocalStorage(settings.upload_dir)


storage_backend = _create_backend()


def validate_resume(file: UploadFile) -> None:
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise ValueError("Only PDF files are accepted.")
    if file.size and file.size > MAX_FILE_SIZE:
        raise ValueError("File size must not exceed 10 MB.")


async def save_resume(file: UploadFile) -> str:
    validate_resume(file)
    ext = os.path.splitext(file.filename or "resume.pdf")[1] or ".pdf"
    unique_name = f"{uuid.uuid4().hex}{ext}"
    return await storage_backend.save(file, unique_name)
