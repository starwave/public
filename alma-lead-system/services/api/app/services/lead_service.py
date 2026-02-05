import uuid

from fastapi import UploadFile
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lead import Lead, LeadStatus
from app.services import email_service, storage_service


async def create_lead(
    db: AsyncSession,
    first_name: str,
    last_name: str,
    email: str,
    resume: UploadFile,
) -> Lead:
    resume_path = await storage_service.save_resume(resume)

    lead = Lead(
        first_name=first_name,
        last_name=last_name,
        email=email,
        resume_path=resume_path,
    )
    db.add(lead)
    await db.commit()
    await db.refresh(lead)
    return lead


async def send_lead_emails(first_name: str, last_name: str, email: str) -> None:
    await email_service.send_prospect_confirmation(email, first_name, last_name)
    await email_service.send_attorney_notification(first_name, last_name, email)


async def list_leads(
    db: AsyncSession,
    page: int = 1,
    page_size: int = 20,
    status: LeadStatus | None = None,
) -> tuple[list[Lead], int]:
    query = select(Lead)
    count_query = select(func.count(Lead.id))

    if status:
        query = query.where(Lead.status == status)
        count_query = count_query.where(Lead.status == status)

    total = (await db.execute(count_query)).scalar() or 0

    query = (
        query.order_by(Lead.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(query)
    leads = list(result.scalars().all())
    return leads, total


async def update_lead_status(
    db: AsyncSession, lead_id: uuid.UUID, status: LeadStatus
) -> Lead | None:
    result = await db.execute(select(Lead).where(Lead.id == lead_id))
    lead = result.scalar_one_or_none()
    if not lead:
        return None
    lead.status = status
    await db.commit()
    await db.refresh(lead)
    return lead
