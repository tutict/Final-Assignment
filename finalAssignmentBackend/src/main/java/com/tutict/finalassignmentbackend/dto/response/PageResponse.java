package com.tutict.finalassignmentbackend.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class PageResponse<T> {

    private List<T> content;
    private long total;
    private int page;
    private int size;

    public static <T> PageResponse<T> of(List<T> content, long total, int page, int size) {
        return PageResponse.<T>builder()
                .content(content)
                .total(total)
                .page(page)
                .size(size)
                .build();
    }
}
