package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.LoginLog;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDateTime;

@Data
@Document(indexName = "login_logs")
@Setting(settingPath = "elasticsearch/login-log-analyzer.json")
public class LoginLogDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer logId;

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
    private String loginIpAddress;

    @Field(type = FieldType.Date, format = DateFormat.date_time, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime loginTime;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String loginResult;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String browserType;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String osVersion;

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

    // 从 LoginLog 实体转换为文档
    public static LoginLogDocument fromEntity(LoginLog entity) {
        if (entity == null) {
            return null;
        }

        LoginLogDocument doc = new LoginLogDocument();
        doc.setLogId(entity.getLogId());
        doc.setUsername(entity.getUsername()); // 会自动同步 usernameCompletion
        doc.setLoginIpAddress(entity.getLoginIpAddress());
        doc.setLoginTime(entity.getLoginTime());
        doc.setLoginResult(entity.getLoginResult());
        doc.setBrowserType(entity.getBrowserType());
        doc.setOsVersion(entity.getOsVersion());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    // 从文档转换为 LoginLog 实体
    public LoginLog toEntity() {
        LoginLog entity = new LoginLog();
        entity.setLogId(this.logId);
        entity.setUsername(this.username);
        entity.setLoginIpAddress(this.loginIpAddress);
        entity.setLoginTime(this.loginTime);
        entity.setLoginResult(this.loginResult);
        entity.setBrowserType(this.browserType);
        entity.setOsVersion(this.osVersion);
        entity.setRemarks(this.remarks);
        return entity;
    }
}