package io.bitnomio.coeff.shared.util;

import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Utility for paginating in-memory lists.
 *
 * <p>Produces a {@code Map} with {@code "data"} (the sublist) and
 * {@code "meta"} ({@code total}, {@code offset}, {@code limit}) keys,
 * matching Javalin's {@code PaginationHelper.paginate()} contract.
 *
 * @since 1.0
 */
public final class PaginationHelper {

    private PaginationHelper() {
        // utility class
    }

    /**
     * Paginates a list given an offset and limit.
     *
     * @param data   the full list (may be {@code null})
     * @param offset zero-based offset; clamped to 0 if negative
     * @param limit  maximum page size; clamped to 1 if non-positive
     * @param <T>    element type
     * @return {@code {data: [...], meta: {total, offset, limit}}}
     */
    public static <T> Map<String, Object> paginate(List<T> data, int offset, int limit) {
        if (data == null) data = Collections.emptyList();
        int safeOffset = Math.max(offset, 0);
        int safeLimit = Math.max(limit, 1);
        int total = data.size();
        int from = Math.min(safeOffset, total);
        int to = Math.min(from + safeLimit, total);
        List<T> page = data.subList(from, to);
        return Map.of(
                "data", page,
                "meta", Map.of("total", total, "offset", safeOffset, "limit", safeLimit)
        );
    }
}
