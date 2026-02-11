import logging

from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, Request, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import limiter
from app.schemas.lead import LeadResponse
from app.services import lead_service

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Leads"])


@router.post(
    "/leads",
    response_model=LeadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a new lead (public)",
)
@limiter.limit("10/minute")
@limiter.limit("100/hour")
async def create_lead(
    request: Request,
    background_tasks: BackgroundTasks,
    first_name: str = Form(..., min_length=1, max_length=100),
    last_name: str = Form(..., min_length=1, max_length=100),
    email: str = Form(...),
    resume: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    try:
        lead = await lead_service.create_lead(
            db=db,
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            email=email.strip().lower(),
            resume=resume,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    background_tasks.add_task(
        lead_service.send_lead_emails,
        first_name=lead.first_name,
        last_name=lead.last_name,
        email=lead.email,
    )

    return lead
