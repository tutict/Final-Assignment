package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AppealManagementSearchRepository extends ElasticsearchRepository<AppealManagementDocument, Integer> {

    List<AppealManagementDocument> findByAppellantNameContaining(String name);

    List<AppealManagementDocument> findByIdCardNumber(String idCardNumber);

    List<AppealManagementDocument> findByContactNumber(String contactNumber);

    List<AppealManagementDocument> findByOffenseId(Integer offenseId);

    List<AppealManagementDocument> findByProcessStatus(String processStatus);

    List<AppealManagementDocument> findByAppealTimeBetween(LocalDateTime startTime, LocalDateTime endTime);

    List<AppealManagementDocument> findByAppealReasonContaining(String reason);

    List<AppealManagementDocument> findByProcessStatusAndAppealTimeBetween(
            String processStatus,
            LocalDateTime startTime,
            LocalDateTime endTime
    );

    long countByProcessStatus(String processStatus);
}