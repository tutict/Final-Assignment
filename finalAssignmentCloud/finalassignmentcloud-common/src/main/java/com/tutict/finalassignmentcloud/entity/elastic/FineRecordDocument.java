package com.tutict.finalassignmentcloud.entity.elastic;

import com.tutict.finalassignmentcloud.entity.FineRecord;
import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
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
@Document(indexName = "fine_record")
@Setting(settingPath = "elasticsearch/fine_record-settings.json")
public class FineRecordDocument implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @Id
    @Field(type = FieldType.Long)
    private Long fineId;

    @Field(type = FieldType.Long)
    private Long offenseId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String fineNumber;

    @Field(type = FieldType.Double)
    private BigDecimal fineAmount;

    @Field(type = FieldType.Double)
    private BigDecimal lateFee;

    @Field(type = FieldType.Double)
    private BigDecimal totalAmount;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate fineDate;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate paymentDeadline;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String issuingAuthority;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String handler;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String approver;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String paymentStatus;

    @Field(type = FieldType.Double)
    private BigDecimal paidAmount;

    @Field(type = FieldType.Double)
    private BigDecimal unpaidAmount;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String createdBy;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String updatedBy;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime deletedAt;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String remarks;

    public static FineRecordDocument fromEntity(FineRecord entity) {
        if (entity == null) {
            return null;
        }
        FineRecordDocument doc = new FineRecordDocument();
        doc.setFineId(entity.getFineId());
        doc.setOffenseId(entity.getOffenseId());
        doc.setFineNumber(entity.getFineNumber());
        doc.setFineAmount(entity.getFineAmount());
        doc.setLateFee(entity.getLateFee());
        doc.setTotalAmount(entity.getTotalAmount());
        doc.setFineDate(entity.getFineDate());
        doc.setPaymentDeadline(entity.getPaymentDeadline());
        doc.setIssuingAuthority(entity.getIssuingAuthority());
        doc.setHandler(entity.getHandler());
        doc.setApprover(entity.getApprover());
        doc.setPaymentStatus(entity.getPaymentStatus());
        doc.setPaidAmount(entity.getPaidAmount());
        doc.setUnpaidAmount(entity.getUnpaidAmount());
        doc.setCreatedAt(entity.getCreatedAt());
        doc.setUpdatedAt(entity.getUpdatedAt());
        doc.setCreatedBy(entity.getCreatedBy());
        doc.setUpdatedBy(entity.getUpdatedBy());
        doc.setDeletedAt(entity.getDeletedAt());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    public FineRecord toEntity() {
        FineRecord entity = new FineRecord();
        entity.setFineId(this.fineId);
        entity.setOffenseId(this.offenseId);
        entity.setFineNumber(this.fineNumber);
        entity.setFineAmount(this.fineAmount);
        entity.setLateFee(this.lateFee);
        entity.setTotalAmount(this.totalAmount);
        entity.setFineDate(this.fineDate);
        entity.setPaymentDeadline(this.paymentDeadline);
        entity.setIssuingAuthority(this.issuingAuthority);
        entity.setHandler(this.handler);
        entity.setApprover(this.approver);
        entity.setPaymentStatus(this.paymentStatus);
        entity.setPaidAmount(this.paidAmount);
        entity.setUnpaidAmount(this.unpaidAmount);
        entity.setCreatedAt(this.createdAt);
        entity.setUpdatedAt(this.updatedAt);
        entity.setCreatedBy(this.createdBy);
        entity.setUpdatedBy(this.updatedBy);
        entity.setDeletedAt(this.deletedAt);
        entity.setRemarks(this.remarks);
        return entity;
    }
}

