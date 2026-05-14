package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("appeal_review")
public class AppealReview implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "review_id", type = IdType.AUTO)
    private Long reviewId;

    @TableField("appeal_id")
    private Long appealId;

    @TableField("review_level")
    @NotBlank(message = "reviewLevel must not be blank")
    @Size(max = 50, message = "reviewLevel must not exceed 50 characters")
    private String reviewLevel;

    @TableField("review_time")
    @PastOrPresent(message = "reviewTime must not be in the future")
    private LocalDateTime reviewTime;

    @TableField("reviewer")
    @NotBlank(message = "reviewer must not be blank")
    @Size(max = 100, message = "reviewer must not exceed 100 characters")
    private String reviewer;

    @TableField("reviewer_dept")
    @Size(max = 100, message = "reviewerDept must not exceed 100 characters")
    private String reviewerDept;

    @TableField("review_result")
    @NotBlank(message = "reviewResult must not be blank")
    @Size(max = 50, message = "reviewResult must not exceed 50 characters")
    private String reviewResult;

    @TableField("review_opinion")
    @Size(max = 2000, message = "reviewOpinion must not exceed 2000 characters")
    private String reviewOpinion;

    @TableField("suggested_action")
    @Size(max = 100, message = "suggestedAction must not exceed 100 characters")
    private String suggestedAction;

    @TableField("suggested_fine_amount")
    @DecimalMin(value = "0.0", message = "suggestedFineAmount must not be negative")
    private BigDecimal suggestedFineAmount;

    @TableField("suggested_points")
    @PositiveOrZero(message = "suggestedPoints must not be negative")
    private Integer suggestedPoints;

    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(value = "updated_at", fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;

    @TableField("remarks")
    @Size(max = 1000, message = "remarks must not exceed 1000 characters")
    private String remarks;
}
