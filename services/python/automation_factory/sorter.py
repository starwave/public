"""
Package sorting module for Thoughtful's robotic automation factory.

This module provides functionality to dispatch packages to the correct stack
based on their volume and mass.
"""

from typing import Literal

# Constants for package classification thresholds
VOLUME_THRESHOLD = 1_000_000  # cm^3
DIMENSION_THRESHOLD = 150  # cm
MASS_THRESHOLD = 20  # kg

# Stack names
STANDARD = "STANDARD"
SPECIAL = "SPECIAL"
REJECTED = "REJECTED"

StackType = Literal["STANDARD", "SPECIAL", "REJECTED"]


def is_bulky(width: float, height: float, length: float) -> bool:
    """
    Determine if a package is bulky based on its dimensions.

    A package is bulky if:
    - Its volume (width x height x length) >= 1,000,000 cm^3, OR
    - Any single dimension >= 150 cm

    Args:
        width: Package width in centimeters.
        height: Package height in centimeters.
        length: Package length in centimeters.

    Returns:
        True if the package is bulky, False otherwise.
    """
    volume = width * height * length
    if volume >= VOLUME_THRESHOLD:
        return True
    if width >= DIMENSION_THRESHOLD or height >= DIMENSION_THRESHOLD or length >= DIMENSION_THRESHOLD:
        return True
    return False


def is_heavy(mass: float) -> bool:
    """
    Determine if a package is heavy based on its mass.

    A package is heavy if its mass >= 20 kg.

    Args:
        mass: Package mass in kilograms.

    Returns:
        True if the package is heavy, False otherwise.
    """
    return mass >= MASS_THRESHOLD


def sort(width: float, height: float, length: float, mass: float) -> StackType:
    """
    Dispatch a package to the correct stack based on its volume and mass.

    Sorting rules:
    - REJECTED: Packages that are both heavy and bulky.
    - SPECIAL: Packages that are either heavy or bulky (but not both).
    - STANDARD: Packages that are neither heavy nor bulky.

    Args:
        width: Package width in centimeters.
        height: Package height in centimeters.
        length: Package length in centimeters.
        mass: Package mass in kilograms.

    Returns:
        The name of the stack where the package should go:
        "STANDARD", "SPECIAL", or "REJECTED".

    Raises:
        ValueError: If any dimension or mass is negative.
    """
    if width < 0 or height < 0 or length < 0 or mass < 0:
        raise ValueError("Dimensions and mass must be non-negative values")

    bulky = is_bulky(width, height, length)
    heavy = is_heavy(mass)

    if bulky and heavy:
        return REJECTED
    elif bulky or heavy:
        return SPECIAL
    else:
        return STANDARD
