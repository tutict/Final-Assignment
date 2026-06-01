package com.tutict.finalassignmentcloud.rag.support;

public final class PageLimits {

    public static final int DEFAULT_PAGE = 1;
    public static final int DEFAULT_SIZE = 20;
    public static final int MAX_PAGE_SIZE = 100;
    public static final int MAX_BATCH_SIZE = 200;

    private PageLimits() {
    }

    public static int normalizePage(int page) {
        return Math.max(page, DEFAULT_PAGE);
    }

    public static int normalizeSize(int size) {
        return normalizeLimit(size, MAX_PAGE_SIZE);
    }

    public static int normalizeLimit(int limit) {
        return normalizeLimit(limit, MAX_PAGE_SIZE);
    }

    public static int normalizeBatchSize(int size) {
        return normalizeLimit(size, MAX_BATCH_SIZE);
    }

    public static int normalizeLimit(int limit, int max) {
        int safeMax = Math.max(max, 1);
        return Math.min(Math.max(limit, 1), safeMax);
    }
}
