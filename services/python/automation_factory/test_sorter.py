"""
Unit tests for the package sorting module.
"""

import pytest

from sorter import sort, is_bulky, is_heavy, STANDARD, SPECIAL, REJECTED


class TestIsBulky:
    """Tests for the is_bulky function."""

    def test_small_package_not_bulky(self):
        """A small package should not be bulky."""
        assert is_bulky(10, 10, 10) is False

    def test_volume_at_threshold_is_bulky(self):
        """A package with volume exactly at threshold should be bulky."""
        # 100 * 100 * 100 = 1,000,000
        assert is_bulky(100, 100, 100) is True

    def test_volume_above_threshold_is_bulky(self):
        """A package with volume above threshold should be bulky."""
        assert is_bulky(200, 200, 200) is True

    def test_volume_below_threshold_not_bulky(self):
        """A package with volume just below threshold should not be bulky."""
        # 99 * 100 * 100 = 990,000
        assert is_bulky(99, 100, 100) is False

    def test_single_dimension_at_threshold_is_bulky(self):
        """A package with one dimension at threshold should be bulky."""
        assert is_bulky(150, 10, 10) is True
        assert is_bulky(10, 150, 10) is True
        assert is_bulky(10, 10, 150) is True

    def test_single_dimension_above_threshold_is_bulky(self):
        """A package with one dimension above threshold should be bulky."""
        assert is_bulky(200, 10, 10) is True
        assert is_bulky(10, 200, 10) is True
        assert is_bulky(10, 10, 200) is True

    def test_dimension_just_below_threshold_not_bulky(self):
        """A package with dimensions just below threshold should not be bulky."""
        assert is_bulky(149, 149, 44) is False  # Volume = 976,904


class TestIsHeavy:
    """Tests for the is_heavy function."""

    def test_light_package_not_heavy(self):
        """A light package should not be heavy."""
        assert is_heavy(10) is False

    def test_mass_at_threshold_is_heavy(self):
        """A package with mass exactly at threshold should be heavy."""
        assert is_heavy(20) is True

    def test_mass_above_threshold_is_heavy(self):
        """A package with mass above threshold should be heavy."""
        assert is_heavy(25) is True

    def test_mass_just_below_threshold_not_heavy(self):
        """A package with mass just below threshold should not be heavy."""
        assert is_heavy(19.99) is False

    def test_zero_mass_not_heavy(self):
        """A package with zero mass should not be heavy."""
        assert is_heavy(0) is False


class TestSort:
    """Tests for the sort function."""

    # STANDARD tests (neither bulky nor heavy)
    def test_standard_small_light_package(self):
        """A small, light package should go to STANDARD."""
        assert sort(10, 10, 10, 5) == STANDARD

    def test_standard_near_thresholds(self):
        """A package just under all thresholds should go to STANDARD."""
        assert sort(99, 100, 100, 19.99) == STANDARD

    def test_standard_zero_dimensions(self):
        """A package with zero dimensions should go to STANDARD."""
        assert sort(0, 0, 0, 0) == STANDARD

    # SPECIAL tests (either bulky OR heavy, but not both)
    def test_special_bulky_by_volume_not_heavy(self):
        """A bulky (by volume) but not heavy package should go to SPECIAL."""
        assert sort(100, 100, 100, 10) == SPECIAL

    def test_special_bulky_by_dimension_not_heavy(self):
        """A bulky (by dimension) but not heavy package should go to SPECIAL."""
        assert sort(150, 10, 10, 10) == SPECIAL

    def test_special_heavy_not_bulky(self):
        """A heavy but not bulky package should go to SPECIAL."""
        assert sort(10, 10, 10, 20) == SPECIAL

    def test_special_heavy_only(self):
        """A heavy-only package should go to SPECIAL."""
        assert sort(50, 50, 50, 25) == SPECIAL

    # REJECTED tests (both bulky AND heavy)
    def test_rejected_bulky_by_volume_and_heavy(self):
        """A package that is bulky by volume and heavy should be REJECTED."""
        assert sort(100, 100, 100, 20) == REJECTED

    def test_rejected_bulky_by_dimension_and_heavy(self):
        """A package that is bulky by dimension and heavy should be REJECTED."""
        assert sort(150, 10, 10, 20) == REJECTED

    def test_rejected_very_large_and_heavy(self):
        """A very large and heavy package should be REJECTED."""
        assert sort(200, 200, 200, 100) == REJECTED

    def test_rejected_exactly_at_all_thresholds(self):
        """A package exactly at all thresholds should be REJECTED."""
        assert sort(150, 1, 1, 20) == REJECTED

    # Edge cases
    def test_negative_dimension_raises_error(self):
        """Negative dimensions should raise ValueError."""
        with pytest.raises(ValueError):
            sort(-10, 10, 10, 5)

    def test_negative_mass_raises_error(self):
        """Negative mass should raise ValueError."""
        with pytest.raises(ValueError):
            sort(10, 10, 10, -5)

    def test_float_dimensions(self):
        """Float dimensions should be handled correctly."""
        assert sort(99.9, 100.1, 100.0, 10) == STANDARD

    def test_float_mass(self):
        """Float mass should be handled correctly."""
        assert sort(10, 10, 10, 19.999) == STANDARD
        assert sort(10, 10, 10, 20.001) == SPECIAL


class TestIntegration:
    """Integration tests for realistic scenarios."""

    def test_typical_small_parcel(self):
        """A typical small parcel (like a book)."""
        assert sort(20, 15, 5, 0.5) == STANDARD

    def test_typical_medium_box(self):
        """A typical medium box (like a shoebox)."""
        assert sort(35, 25, 15, 2) == STANDARD

    def test_large_furniture_piece(self):
        """A large furniture piece (bulky and heavy)."""
        assert sort(200, 100, 50, 30) == REJECTED

    def test_lightweight_large_item(self):
        """A lightweight but large item (like a poster tube)."""
        assert sort(150, 10, 10, 0.5) == SPECIAL

    def test_small_heavy_item(self):
        """A small but heavy item (like weights)."""
        assert sort(20, 20, 20, 25) == SPECIAL


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
