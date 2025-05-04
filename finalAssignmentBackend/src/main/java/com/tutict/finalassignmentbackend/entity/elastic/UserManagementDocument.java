package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDateTime;

@Data
@Document(indexName = "users")
@Setting(settingPath = "elasticsearch/users-analyzer.json")
public class UserManagementDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer userId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String username;

    // 用于补全的字段，存储原始值
    @CompletionField(maxInputLength = 100)
    private String usernameCompletion;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String password;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String contactNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String email;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String status;

    @Field(type = FieldType.Date, format = DateFormat.date_time, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdTime;

    @Field(type = FieldType.Date, format = DateFormat.date_time, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime modifiedTime;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String remarks;

    // 自定义 setter 确保 usernameCompletion 一致性
    public void setUsername(String username) {
        this.username = username;
        this.usernameCompletion = username; // 同步 usernameCompletion
    }

    // 从 UserManagement 实体转换为文档
    public static UserManagementDocument fromEntity(UserManagement entity) {
        if (entity == null) {
            return null;
        }

        UserManagementDocument doc = new UserManagementDocument();
        doc.setUserId(entity.getUserId());
        doc.setUsername(entity.getUsername()); // 会自动同步 usernameCompletion
        doc.setPassword(entity.getPassword());
        doc.setContactNumber(entity.getContactNumber());
        doc.setEmail(entity.getEmail());
        doc.setStatus(entity.getStatus());
        doc.setCreatedTime(entity.getCreatedTime());
        doc.setModifiedTime(entity.getModifiedTime());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    // 从文档转换为 UserManagement 实体
    public UserManagement toEntity() {
        UserManagement entity = new UserManagement();
        entity.setUserId(this.userId);
        entity.setUsername(this.username);
        entity.setPassword(this.password);
        entity.setContactNumber(this.contactNumber);
        entity.setEmail(this.email);
        entity.setStatus(this.status);
        entity.setCreatedTime(this.createdTime);
        entity.setModifiedTime(this.modifiedTime);
        entity.setRemarks(this.remarks);
        return entity;
    }
}