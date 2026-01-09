package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 申诉记录表实体类，对应数据库??"appeal_record"
 * 记录对违法记录的申诉信息
 */
@Data
@TableName("appeal_record")
public class AppealRecord implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 申诉记录 ID，主键，自动增长
     */
    @TableId(value = "appeal_id", type = IdType.AUTO)
    private Long appealId;

    /**
     * 违法记录 ID
     */
    @TableField("offense_id")
    private Long offenseId;

    /**
     * 申诉编号
     */
    @TableField("appeal_number")
    private String appealNumber;

    /**
     * 申诉人姓??
     */
    @TableField("appellant_name")
    private String appellantName;

    /**
     * 申诉人身份证??
     */
    @TableField("appellant_id_card")
    private String appellantIdCard;

    /**
     * 申诉人联系电??
     */
    @TableField("appellant_contact")
    private String appellantContact;

    /**
     * 申诉人电子邮??
     */
    @TableField("appellant_email")
    private String appellantEmail;

    /**
     * 申诉人联系地址
     */
    @TableField("appellant_address")
    private String appellantAddress;

    /**
     * 申诉类型 (Information_Error, Equipment_Error, Judgment_Error, Force_Majeure, Other)
     */
    @TableField("appeal_type")
    private String appealType;

    /**
     * 申诉理由
     */
    @TableField("appeal_reason")
    private String appealReason;

    /**
     * 申诉时间
     */
    @TableField("appeal_time")
    private LocalDateTime appealTime;

    /**
     * 证据说明
     */
    @TableField("evidence_description")
    private String evidenceDescription;

    /**
     * 证据文件 URL 列表 (JSON数组)
     */
    @TableField("evidence_urls")
    private String evidenceUrls;

    /**
     * 受理状??(Pending, Accepted, Rejected, Need_Supplement)
     */
    @TableField("acceptance_status")
    private String acceptanceStatus;

    /**
     * 受理时间
     */
    @TableField("acceptance_time")
    private LocalDateTime acceptanceTime;

    /**
     * 受理??
     */
    @TableField("acceptance_handler")
    private String acceptanceHandler;

    /**
     * 不予受理原因
     */
    @TableField("rejection_reason")
    private String rejectionReason;

    /**
     * 处理状??(Unprocessed, Under_Review, Approved, Rejected, Withdrawn)
     */
    @TableField("process_status")
    private String processStatus;

    /**
     * 处理时间
     */
    @TableField("process_time")
    private LocalDateTime processTime;

    /**
     * 处理结果
     */
    @TableField("process_result")
    private String processResult;

    /**
     * 处理??
     */
    @TableField("process_handler")
    private String processHandler;

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
     * 创建??
     */
    @TableField("created_by")
    private String createdBy;

    /**
     * 更新??
     */
    @TableField("updated_by")
    private String updatedBy;

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
