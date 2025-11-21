"""
FastAPI REST API for package sorting service.

Provides endpoints to sort packages into appropriate stacks
based on their dimensions and mass.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, field_validator

from sorter import sort, StackType

app = FastAPI(
    title="Package Sorter API",
    description="API for Thoughtful's robotic automation factory package sorting system",
    version="1.0.0",
)


class PackageInput(BaseModel):
    """Input model for package dimensions and mass."""

    width: float = Field(..., description="Package width in centimeters", ge=0)
    height: float = Field(..., description="Package height in centimeters", ge=0)
    length: float = Field(..., description="Package length in centimeters", ge=0)
    mass: float = Field(..., description="Package mass in kilograms", ge=0)

    @field_validator("width", "height", "length", "mass")
    @classmethod
    def must_be_non_negative(cls, v: float) -> float:
        if v < 0:
            raise ValueError("Value must be non-negative")
        return v


class SortResponse(BaseModel):
    """Response model for package sorting result."""

    stack: StackType = Field(..., description="The stack where the package should go")
    width: float = Field(..., description="Package width in centimeters")
    height: float = Field(..., description="Package height in centimeters")
    length: float = Field(..., description="Package length in centimeters")
    mass: float = Field(..., description="Package mass in kilograms")


@app.get("/")
def root() -> dict:
    """Root endpoint with API information."""
    return {
        "service": "Package Sorter API",
        "version": "1.0.0",
        "description": "Sort packages into STANDARD, SPECIAL, or REJECTED stacks",
    }


@app.post("/sort", response_model=SortResponse)
def sort_package(package: PackageInput) -> SortResponse:
    """
    Sort a package into the appropriate stack.

    - STANDARD: Packages that are neither bulky nor heavy.
    - SPECIAL: Packages that are either bulky or heavy (but not both).
    - REJECTED: Packages that are both bulky and heavy.

    A package is bulky if its volume >= 1,000,000 cm^3 or any dimension >= 150 cm.
    A package is heavy if its mass >= 20 kg.
    """
    try:
        stack = sort(package.width, package.height, package.length, package.mass)
        return SortResponse(
            stack=stack,
            width=package.width,
            height=package.height,
            length=package.length,
            mass=package.mass,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/sort")
def sort_package_get(
    width: float,
    height: float,
    length: float,
    mass: float,
) -> SortResponse:
    """
    Sort a package using GET parameters (alternative to POST).

    Query parameters:
    - width: Package width in centimeters (must be >= 0)
    - height: Package height in centimeters (must be >= 0)
    - length: Package length in centimeters (must be >= 0)
    - mass: Package mass in kilograms (must be >= 0)
    """
    if width < 0 or height < 0 or length < 0 or mass < 0:
        raise HTTPException(status_code=400, detail="All values must be non-negative")

    try:
        stack = sort(width, height, length, mass)
        return SortResponse(
            stack=stack,
            width=width,
            height=height,
            length=length,
            mass=mass,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
