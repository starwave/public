import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import limiter, require_api_key
from app.models.lead import LeadStatus
from app.schemas.lead import LeadListResponse, LeadResponse, LeadStatusUpdate
from app.services import lead_service

router = APIRouter(prefix="/internal", tags=["Internal"], dependencies=[Depends(require_api_key)])


@router.get(
    "/leads",
    response_model=LeadListResponse,
    summary="List all leads (internal)",
)
@limiter.limit("60/minute")
async def list_leads(
    request: Request,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status_filter: LeadStatus | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
):
    leads, total = await lead_service.list_leads(
        db=db, page=page, page_size=page_size, status=status_filter
    )
    return LeadListResponse(items=leads, total=total, page=page, page_size=page_size)


@router.patch(
    "/leads/{lead_id}",
    response_model=LeadResponse,
    summary="Update lead status (internal)",
)
@limiter.limit("30/minute")
async def update_lead(
    request: Request,
    lead_id: uuid.UUID,
    body: LeadStatusUpdate,
    db: AsyncSession = Depends(get_db),
):
    lead = await lead_service.update_lead_status(db, lead_id, body.status)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found."
        )
    return lead
