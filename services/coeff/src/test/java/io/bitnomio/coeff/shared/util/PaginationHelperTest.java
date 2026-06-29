package io.bitnomio.coeff.shared.util;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for {@link PaginationHelper}.
 *
 * @since 1.0
 */
class PaginationHelperTest {

    @Test
    void paginateReturnsFirstPage() {
        var items = List.of("a", "b", "c");
        var result = PaginationHelper.paginate(items, 0, 2);
        assertEquals(List.of("a", "b"), result.get("data"));
        assertEquals(Map.of("total", 3, "offset", 0, "limit", 2), result.get("meta"));
    }

    @Test
    void paginateReturnsSecondPage() {
        var items = List.of("a", "b", "c");
        var result = PaginationHelper.paginate(items, 2, 2);
        assertEquals(List.of("c"), result.get("data"));
        assertEquals(Map.of("total", 3, "offset", 2, "limit", 2), result.get("meta"));
    }

    @Test
    void paginateWithOffsetBeyondTotalReturnsEmpty() {
        var items = List.of("a", "b", "c");
        var result = PaginationHelper.paginate(items, 10, 5);
        assertTrue(((List<?>) result.get("data")).isEmpty());
        assertEquals(Map.of("total", 3, "offset", 10, "limit", 5), result.get("meta"));
    }

    @Test
    void paginateWithNegativeOffsetDefaultsToZero() {
        var items = List.of("a", "b", "c");
        var result = PaginationHelper.paginate(items, -1, 2);
        assertEquals(List.of("a", "b"), result.get("data"));
        assertEquals(Map.of("total", 3, "offset", 0, "limit", 2), result.get("meta"));
    }

    @Test
    void paginateWithNegativeLimitDefaultsToOne() {
        var items = List.of("a", "b", "c");
        var result = PaginationHelper.paginate(items, 0, -1);
        assertEquals(List.of("a"), result.get("data"));
        assertEquals(Map.of("total", 3, "offset", 0, "limit", 1), result.get("meta"));
    }

    @Test
    void paginateWithEmptyList() {
        var items = List.of();
        var result = PaginationHelper.paginate(items, 0, 10);
        assertTrue(((List<?>) result.get("data")).isEmpty());
        assertEquals(Map.of("total", 0, "offset", 0, "limit", 10), result.get("meta"));
    }

    @Test
    void paginateWithNullListReturnsEmpty() {
        var result = PaginationHelper.paginate(null, 0, 10);
        assertTrue(((List<?>) result.get("data")).isEmpty());
        assertEquals(Map.of("total", 0, "offset", 0, "limit", 10), result.get("meta"));
    }

    @Test
    void paginateReturnsAllWhenLimitExceedsTotal() {
        var items = List.of("x", "y");
        var result = PaginationHelper.paginate(items, 0, 100);
        assertEquals(List.of("x", "y"), result.get("data"));
        assertEquals(Map.of("total", 2, "offset", 0, "limit", 100), result.get("meta"));
    }
}
