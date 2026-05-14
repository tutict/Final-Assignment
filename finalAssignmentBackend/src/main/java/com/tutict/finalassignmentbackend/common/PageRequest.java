package com.tutict.finalassignmentbackend.common;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
public class PageRequest {

    @Min(value = 0, message = "页码不能为负")
    private int page = 0;

    @Min(value = 1, message = "每页至少 1 条")
    @Max(value = 100, message = "每页最多 100 条")
    private int size = 20;

    public long toMyBatisPage() {
        return (long) page + 1;
    }
}
