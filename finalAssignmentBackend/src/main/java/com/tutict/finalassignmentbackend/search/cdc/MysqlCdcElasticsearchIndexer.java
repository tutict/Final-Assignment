package com.tutict.finalassignmentbackend.search.cdc;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.entity.driver.DriverInformation;
import com.tutict.finalassignmentbackend.entity.driver.VehicleInformation;
import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysUserDocument;
import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import com.tutict.finalassignmentbackend.repository.DriverInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysUserSearchRepository;
import com.tutict.finalassignmentbackend.repository.VehicleInformationSearchRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Component
@ConditionalOnProperty(prefix = "app.cdc.elasticsearch", name = "enabled", havingValue = "true")
public class MysqlCdcElasticsearchIndexer {

    private static final Logger log = LoggerFactory.getLogger(MysqlCdcElasticsearchIndexer.class);

    private final ObjectMapper objectMapper;
    private final DriverInformationSearchRepository driverInformationSearchRepository;
    private final VehicleInformationSearchRepository vehicleInformationSearchRepository;
    private final SysUserSearchRepository sysUserSearchRepository;

    public MysqlCdcElasticsearchIndexer(
            ObjectMapper objectMapper,
            DriverInformationSearchRepository driverInformationSearchRepository,
            VehicleInformationSearchRepository vehicleInformationSearchRepository,
            SysUserSearchRepository sysUserSearchRepository
    ) {
        this.objectMapper = objectMapper;
        this.driverInformationSearchRepository = driverInformationSearchRepository;
        this.vehicleInformationSearchRepository = vehicleInformationSearchRepository;
        this.sysUserSearchRepository = sysUserSearchRepository;
    }

    @KafkaListener(
            id = "mysql-cdc-elasticsearch-indexer",
            topicPattern = "${app.cdc.elasticsearch.topic-pattern:traffic\\.traffic\\.(driver_information|vehicle_information|sys_user)}",
            groupId = "${app.cdc.elasticsearch.group-id:mysql-cdc-elasticsearch-indexer}",
            autoStartup = "${app.cdc.elasticsearch.enabled:false}"
    )
    public void index(String message, @Header(KafkaHeaders.RECEIVED_TOPIC) String topic) {
        if (!StringUtils.hasText(message)) {
            return;
        }
        try {
            JsonNode root = objectMapper.readTree(message);
            JsonNode payload = root.has("payload") ? root.path("payload") : root;
            String table = tableName(payload, topic);
            String op = text(payload, "op");
            JsonNode row = payload.path("after");
            if ("d".equals(op) || row.isMissingNode() || row.isNull()) {
                delete(table, payload.path("before"));
                return;
            }
            upsert(table, row);
        } catch (Exception error) {
            log.error("Failed to index MySQL CDC event to Elasticsearch: topic={}, error={}",
                    topic, error.getMessage(), error);
        }
    }

    private void upsert(String table, JsonNode row) {
        switch (table) {
            case "driver_information" -> {
                DriverInformation entity = toDriverInformation(row);
                if (entity.getDeletedAt() != null) {
                    driverInformationSearchRepository.deleteById(entity.getDriverId());
                } else {
                    driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(entity));
                }
            }
            case "vehicle_information" -> {
                VehicleInformation entity = toVehicleInformation(row);
                if (entity.getDeletedAt() != null) {
                    vehicleInformationSearchRepository.deleteById(entity.getVehicleId());
                } else {
                    vehicleInformationSearchRepository.save(VehicleInformationDocument.fromEntity(entity));
                }
            }
            case "sys_user" -> {
                SysUser entity = toSysUser(row);
                if (entity.getDeletedAt() != null) {
                    sysUserSearchRepository.deleteById(entity.getUserId());
                } else {
                    sysUserSearchRepository.save(SysUserDocument.fromEntity(entity));
                }
            }
            default -> log.debug("Ignored unsupported CDC table: {}", table);
        }
    }

    private void delete(String table, JsonNode row) {
        switch (table) {
            case "driver_information" -> deleteById(driverInformationSearchRepository, longValue(row, "driver_id"));
            case "vehicle_information" -> deleteById(vehicleInformationSearchRepository, longValue(row, "vehicle_id"));
            case "sys_user" -> deleteById(sysUserSearchRepository, longValue(row, "user_id"));
            default -> log.debug("Ignored delete for unsupported CDC table: {}", table);
        }
    }

    private <T> void deleteById(org.springframework.data.elasticsearch.repository.ElasticsearchRepository<T, Long> repository, Long id) {
        if (id != null) {
            repository.deleteById(id);
        }
    }

    private DriverInformation toDriverInformation(JsonNode row) {
        DriverInformation entity = new DriverInformation();
        entity.setDriverId(longValue(row, "driver_id"));
        entity.setAuthUserId(longValue(row, "auth_user_id"));
        entity.setName(text(row, "name"));
        entity.setIdCardNumber(text(row, "id_card_number"));
        entity.setGender(text(row, "gender"));
        entity.setBirthdate(date(row, "birthdate"));
        entity.setContactNumber(text(row, "contact_number"));
        entity.setEmail(text(row, "email"));
        entity.setAddress(text(row, "address"));
        entity.setDriverLicenseNumber(text(row, "driver_license_number"));
        entity.setLicenseType(text(row, "license_type"));
        entity.setFirstLicenseDate(date(row, "first_license_date"));
        entity.setIssueDate(date(row, "issue_date"));
        entity.setExpiryDate(date(row, "expiry_date"));
        entity.setIssuingAuthority(text(row, "issuing_authority"));
        entity.setCurrentPoints(intValue(row, "current_points"));
        entity.setTotalDeductedPoints(intValue(row, "total_deducted_points"));
        entity.setStatus(text(row, "status"));
        entity.setCreatedAt(dateTime(row, "created_at"));
        entity.setUpdatedAt(dateTime(row, "updated_at"));
        entity.setCreatedBy(text(row, "created_by"));
        entity.setUpdatedBy(text(row, "updated_by"));
        entity.setDeletedAt(dateTime(row, "deleted_at"));
        entity.setRemarks(text(row, "remarks"));
        return entity;
    }

    private VehicleInformation toVehicleInformation(JsonNode row) {
        VehicleInformation entity = new VehicleInformation();
        entity.setVehicleId(longValue(row, "vehicle_id"));
        entity.setDriverId(longValue(row, "driver_id"));
        entity.setLicensePlate(text(row, "license_plate"));
        entity.setPlateColor(text(row, "plate_color"));
        entity.setVehicleType(text(row, "vehicle_type"));
        entity.setBrand(text(row, "brand"));
        entity.setModel(text(row, "model"));
        entity.setVehicleColor(text(row, "vehicle_color"));
        entity.setEngineNumber(text(row, "engine_number"));
        entity.setFrameNumber(text(row, "frame_number"));
        entity.setOwnerName(text(row, "owner_name"));
        entity.setOwnerIdCard(text(row, "owner_id_card"));
        entity.setOwnerContact(text(row, "owner_contact"));
        entity.setOwnerAddress(text(row, "owner_address"));
        entity.setFirstRegistrationDate(date(row, "first_registration_date"));
        entity.setRegistrationDate(date(row, "registration_date"));
        entity.setIssuingAuthority(text(row, "issuing_authority"));
        entity.setStatus(text(row, "status"));
        entity.setInspectionExpiryDate(date(row, "inspection_expiry_date"));
        entity.setInsuranceExpiryDate(date(row, "insurance_expiry_date"));
        entity.setCreatedAt(dateTime(row, "created_at"));
        entity.setUpdatedAt(dateTime(row, "updated_at"));
        entity.setCreatedBy(text(row, "created_by"));
        entity.setUpdatedBy(text(row, "updated_by"));
        entity.setDeletedAt(dateTime(row, "deleted_at"));
        entity.setRemarks(text(row, "remarks"));
        return entity;
    }

    private SysUser toSysUser(JsonNode row) {
        SysUser entity = new SysUser();
        entity.setUserId(longValue(row, "user_id"));
        entity.setUsername(text(row, "username"));
        entity.setRealName(text(row, "real_name"));
        entity.setIdCardNumber(text(row, "id_card_number"));
        entity.setGender(text(row, "gender"));
        entity.setContactNumber(text(row, "contact_number"));
        entity.setEmail(text(row, "email"));
        entity.setDepartment(text(row, "department"));
        entity.setPosition(text(row, "position"));
        entity.setEmployeeNumber(text(row, "employee_number"));
        entity.setStatus(text(row, "status"));
        entity.setAccountExpiryDate(date(row, "account_expiry_date"));
        entity.setLoginFailures(intValue(row, "login_failures"));
        entity.setLastLoginTime(dateTime(row, "last_login_time"));
        entity.setLastLoginIp(text(row, "last_login_ip"));
        entity.setPasswordUpdateTime(dateTime(row, "password_update_time"));
        entity.setCreatedAt(dateTime(row, "created_at"));
        entity.setUpdatedAt(dateTime(row, "updated_at"));
        entity.setCreatedBy(text(row, "created_by"));
        entity.setUpdatedBy(text(row, "updated_by"));
        entity.setDeletedAt(dateTime(row, "deleted_at"));
        entity.setRemarks(text(row, "remarks"));
        return entity;
    }

    private String tableName(JsonNode payload, String topic) {
        String table = text(payload.path("source"), "table");
        if (StringUtils.hasText(table)) {
            return table;
        }
        int dot = topic == null ? -1 : topic.lastIndexOf('.');
        return dot < 0 ? topic : topic.substring(dot + 1);
    }

    private static String text(JsonNode node, String field) {
        JsonNode value = node == null ? null : node.get(field);
        return value == null || value.isNull() ? null : value.asText();
    }

    private static Long longValue(JsonNode node, String field) {
        JsonNode value = node == null ? null : node.get(field);
        if (value == null || value.isNull()) {
            return null;
        }
        return value.isNumber() ? value.longValue() : parseLong(value.asText());
    }

    private static Integer intValue(JsonNode node, String field) {
        JsonNode value = node == null ? null : node.get(field);
        if (value == null || value.isNull()) {
            return null;
        }
        return value.isNumber() ? value.intValue() : parseInt(value.asText());
    }

    private static LocalDate date(JsonNode node, String field) {
        JsonNode value = node == null ? null : node.get(field);
        if (value == null || value.isNull()) {
            return null;
        }
        if (value.isNumber()) {
            return LocalDate.ofEpochDay(value.longValue());
        }
        String text = value.asText();
        return StringUtils.hasText(text) ? LocalDate.parse(text.substring(0, Math.min(text.length(), 10))) : null;
    }

    private static LocalDateTime dateTime(JsonNode node, String field) {
        JsonNode value = node == null ? null : node.get(field);
        if (value == null || value.isNull()) {
            return null;
        }
        if (value.isNumber()) {
            return LocalDateTime.ofInstant(Instant.ofEpochMilli(value.longValue()), ZoneOffset.UTC);
        }
        String text = value.asText();
        if (!StringUtils.hasText(text)) {
            return null;
        }
        return LocalDateTime.parse(text.replace(" ", "T"));
    }

    private static Long parseLong(String value) {
        try {
            return StringUtils.hasText(value) ? Long.parseLong(value) : null;
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private static Integer parseInt(String value) {
        try {
            return StringUtils.hasText(value) ? Integer.parseInt(value) : null;
        } catch (NumberFormatException ignored) {
            return null;
        }
    }
}
