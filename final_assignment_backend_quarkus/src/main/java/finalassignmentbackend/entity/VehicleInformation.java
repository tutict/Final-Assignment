package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;

@Data
@TableName("vehicle_information")
public class VehicleInformation implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "vehicle_id", type = IdType.AUTO)
    private Integer vehicleId;

    @TableField("license_plate")
    private String licensePlate;

    @TableField("vehicle_type")
    private String vehicleType;

    @TableField("owner_name")
    private String ownerName;

    @TableField("id_card_number")
    private String idCardNumber;

    @TableField("contact_number")
    private String contactNumber;

    @TableField("engine_number")
    private String engineNumber;

    @TableField("frame_number")
    private String frameNumber;

    @TableField("vehicle_color")
    private String vehicleColor;

    @TableField("first_registration_date")
    private LocalDate firstRegistrationDate;

    @TableField("current_status")
    private String currentStatus;
}
