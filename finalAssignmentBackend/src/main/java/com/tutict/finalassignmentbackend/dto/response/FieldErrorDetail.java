package com.tutict.finalassignmentbackend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FieldErrorDetail {
    private String field;
    private String message;
}
