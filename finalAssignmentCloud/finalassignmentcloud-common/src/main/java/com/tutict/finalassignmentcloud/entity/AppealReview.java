package com.tutict.finalassignmentcloud.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 申诉审核表实体类，对应数据库表"appeal_review"
 * 记录申诉的审核信息
 */
@Data
@TableName("appeal_review")
public class AppealReview implements Serializable {
    /**
     * 序列化版本UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 审核记录 ID，主键，自动增长
     */
    @TableId(value = "review_id", type = IdType.AUTO)
    private Long reviewId;

    /**
     * 申诉记录 ID
     */
    @TableField("appeal_id")
    private Long appealId;

    /**
     * 审核级别 (Primary, Secondary, Final)
     */
    @TableField("review_level")
    private String reviewLevel;

    /**
     * 审核时间
     */
    @TableField("review_time")
    private LocalDateTime reviewTime;

    /**
     * 审核人
     */
    @TableField("reviewer")
    private String reviewer;

    /**
     * 审核部门
     */
    @TableField("reviewer_dept")
    private String reviewerDept;

    /**
     * 审核结果 (Approved, Rejected, Need_Resubmit, Transfer)
     */
    @TableField("review_result")
    private String reviewResult;

    /**
     * 审核意见
     */
    @TableField("review_opinion")
    private String reviewOpinion;

    /**
     * 处理建议 (Cancel_Offense, Reduce_Fine, Reduce_Points, Reject_Appeal, Other)
     */
    @TableField("suggested_action")
    private String suggestedAction;

    /**
     * 建议罚款金额 (元)
     */
    @TableField("suggested_fine_amount")
    private BigDecimal suggestedFineAmount;

    /**
     * 建议扣分
     */
    @TableField("suggested_points")
    private Integer suggestedPoints;

    /**
     * 创建时间
     */
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    @TableField(value = "updated_at", fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;

    /**
     * 备注
     */
    @TableField("remarks")
    private String remarks;
}

