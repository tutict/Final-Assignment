package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 扣分信息实体类
 * 该类表示扣分信息的相关属性和操作，实现了Serializable接口，确保对象可以序列化
 * 它的字段与数据库中的扣分信息表中的列相对应
 */
@Data
@TableName("deduction_information")
public class DeductionInformation implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "deduction_id", type = IdType.AUTO)
    private Integer deductionId;

    /**
     * 违纪行为ID
     */
    @TableField("offense_id")
    private Integer offenseId;

    /**
     * 扣除分数
     * 该字段表示因违纪行为而扣除的分数
     */
    @TableField("deducted_points")
    private Integer deductedPoints;

    /**
     * 扣分时间
     * 该字段记录执行扣分的具体时间
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @TableField("deduction_time")
    private LocalDateTime deductionTime;

    /**
     * 处理人
     * 该字段记录负责处理此次扣分的人员姓名
     */
    @TableField("handler")
    private String handler;

    /**
     * 审批人
     * 该字段记录对此次扣分进行审批的人员姓名
     */
    @TableField("approver")
    private String approver;

    /**
     * 备注
     * 该字段用于记录关于此次扣分的额外说明或备注信息
     */
    @TableField("remarks")
    private String remarks;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}
