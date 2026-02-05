"""create leads table

Revision ID: 001
Revises:
Create Date: 2024-01-01 00:00:00.000000
"""

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision = "001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    lead_status = postgresql.ENUM("PENDING", "REACHED_OUT", name="lead_status", create_type=False)
    lead_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "leads",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("first_name", sa.String(100), nullable=False),
        sa.Column("last_name", sa.String(100), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("resume_path", sa.String(500), nullable=False),
        sa.Column(
            "status",
            postgresql.ENUM("PENDING", "REACHED_OUT", name="lead_status", create_type=False),
            server_default="PENDING",
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_leads_email", "leads", ["email"])
    op.create_index("idx_leads_status", "leads", ["status"])
    op.create_index("idx_leads_created_at", "leads", [sa.text("created_at DESC")])


def downgrade() -> None:
    op.drop_table("leads")
    op.execute("DROP TYPE IF EXISTS lead_status")
