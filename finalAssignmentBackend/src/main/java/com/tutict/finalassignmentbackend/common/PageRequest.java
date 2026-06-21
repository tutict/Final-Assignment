package com.tutict.finalassignmentbackend.common;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
public class PageRequest {

    @Min(value = 0, message = "page must be >= 0")
    private int page = 0;

    @Min(value = 1, message = "size must be >= 1")
    @Max(value = PageLimits.MAX_PAGE_SIZE, message = "size must be <= 100")
    private int size = PageLimits.DEFAULT_SIZE;

    public int getPage() {
        return Math.max(page, 0);
    }

    public void setPage(int page) {
        this.page = Math.max(page, 0);
    }

    public int getSize() {
        return PageLimits.normalizeSize(size);
    }

    public void setSize(int size) {
        this.size = PageLimits.normalizeSize(size);
    }

    public long toMyBatisPage() {
        return (long) getPage() + 1;
    }
}
