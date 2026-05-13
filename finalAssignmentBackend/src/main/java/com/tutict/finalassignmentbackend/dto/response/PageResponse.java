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
}
