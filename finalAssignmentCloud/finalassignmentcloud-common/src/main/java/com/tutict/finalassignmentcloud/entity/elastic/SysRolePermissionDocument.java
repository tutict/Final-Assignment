package com.tutict.finalassignmentcloud.entity.elastic;

import com.tutict.finalassignmentcloud.entity.SysRolePermission;
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
@Document(indexName = "sys_role_permission")
@Setting(settingPath = "elasticsearch/sys_role_permission-settings.json")
public class SysRolePermissionDocument implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @Id
    @Field(type = FieldType.Long)
    private Long id;

    @Field(type = FieldType.Integer)
    private Integer roleId;

    @Field(type = FieldType.Integer)
    private Integer permissionId;

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

    public static SysRolePermissionDocument fromEntity(SysRolePermission entity) {
        if (entity == null) {
            return null;
        }
        SysRolePermissionDocument doc = new SysRolePermissionDocument();
        doc.setId(entity.getId());
        doc.setRoleId(entity.getRoleId());
        doc.setPermissionId(entity.getPermissionId());
        doc.setCreatedAt(entity.getCreatedAt());
        doc.setCreatedBy(entity.getCreatedBy());
        doc.setDeletedAt(entity.getDeletedAt());
        return doc;
    }

    public SysRolePermission toEntity() {
        SysRolePermission entity = new SysRolePermission();
        entity.setId(this.id);
        entity.setRoleId(this.roleId);
        entity.setPermissionId(this.permissionId);
        entity.setCreatedAt(this.createdAt);
        entity.setCreatedBy(this.createdBy);
        entity.setDeletedAt(this.deletedAt);
        return entity;
    }
}

