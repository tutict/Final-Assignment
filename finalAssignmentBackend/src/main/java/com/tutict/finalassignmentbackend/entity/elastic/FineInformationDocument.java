package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.FineInformation;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Document(indexName = "fines")
@Setting(settingPath = "elasticsearch/fine-analyzer.json")
public class FineInformationDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer fineId;

    @Field(type = FieldType.Integer)
    private Integer offenseId;

    @Field(type = FieldType.Double)
    private Double fineAmount;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime fineTime; // 罚款时间，格式为 ISO 日期时间

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String payee; // 缴费人姓名

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String accountNumber; // 银行账号

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String bank; // 银行名称

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String receiptNumber; // 收据编号

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String remarks; // 备注信息

    // 从 FineInformation 实体转换为文档
    public static FineInformationDocument fromEntity(FineInformation entity) {
        if (entity == null) {
            return null;
        }

        FineInformationDocument doc = new FineInformationDocument();
        doc.setFineId(entity.getFineId());
        doc.setOffenseId(entity.getOffenseId());
        doc.setFineAmount(entity.getFineAmount() != null ? entity.getFineAmount().doubleValue() : null);
        doc.setFineTime(entity.getFineTime());
        doc.setPayee(entity.getPayee());
        doc.setAccountNumber(entity.getAccountNumber());
        doc.setBank(entity.getBank());
        doc.setReceiptNumber(entity.getReceiptNumber());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    // 从文档转换为 FineInformation 实体
    public FineInformation toEntity() {
        FineInformation entity = new FineInformation();
        entity.setFineId(this.fineId);
        entity.setOffenseId(this.offenseId);
        entity.setFineAmount(this.fineAmount != null ? new BigDecimal(this.fineAmount.toString()) : null);
        entity.setFineTime(this.fineTime);
        entity.setPayee(this.payee);
        entity.setAccountNumber(this.accountNumber);
        entity.setBank(this.bank);
        entity.setReceiptNumber(this.receiptNumber);
        entity.setRemarks(this.remarks);
        return entity;
    }
}