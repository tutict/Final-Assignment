package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.SysUserRole;
import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.DateFormat;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;
import org.springframework.data.elasticsearch.annotations.InnerField;
import org.springframework.data.elasticsearch.annotations.MultiField;
import org.springframework.data.elasticsearch.annotations.Setting;

@Data
@Document(indexName = "sys_user_role")
@Setting(settingPath = "elasticsearch/sys_user_role-settings.json")
public class SysUserRoleDocument implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @Id
    @Field(type = FieldType.Long)
    private Long id;

    @Field(type = FieldType.Long)
    private Long userId;

    @Field(type = FieldType.Integer)
    private Integer roleId;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String createdBy;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime deletedAt;

    public static SysUserRoleDocument fromEntity(SysUserRole entity) {
        if (entity == null) {
            return null;
        }
        SysUserRoleDocument doc = new SysUserRoleDocument();
        doc.setId(entity.getId());
        doc.setUserId(entity.getUserId());
        doc.setRoleId(entity.getRoleId());
        doc.setCreatedAt(entity.getCreatedAt());
        doc.setCreatedBy(entity.getCreatedBy());
        doc.setDeletedAt(entity.getDeletedAt());
        return doc;
    }

    public SysUserRole toEntity() {
        SysUserRole entity = new SysUserRole();
        entity.setId(this.id);
        entity.setUserId(this.userId);
        entity.setRoleId(this.roleId);
        entity.setCreatedAt(this.createdAt);
        entity.setCreatedBy(this.createdBy);
        entity.setDeletedAt(this.deletedAt);
        return entity;
    }
}
