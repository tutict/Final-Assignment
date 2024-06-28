package finalassignmentbackend.entity.relation;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;

@Data
@TableName("offense_fine")
public class OffenseFine implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableField("offense_id")
    private Integer offenseId;

    @TableField("fine_id")
    private Integer fineId;
}