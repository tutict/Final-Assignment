package com.tutict.finalassignmentcloud.system.appeal.query.dto;

public record AppealPageRequest(
        int page,
        int size
) {
    public AppealPageRequest {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    public int zeroBasedPage() {
        return Math.max(page - 1, 0);
    }
}
