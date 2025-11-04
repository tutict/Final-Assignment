package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.AppealReview;
import com.tutict.finalassignmentbackend.entity.elastic.AppealReviewDocument;
import com.tutict.finalassignmentbackend.mapper.AppealReviewMapper;
import com.tutict.finalassignmentbackend.repository.AppealReviewSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AppealReviewService extends AbstractElasticsearchCrudService<AppealReview, AppealReviewDocument, Long> {

    private static final String CACHE_NAME = "appealReviewCache";

    private final AppealReviewSearchRepository repository;

    @Autowired
    public AppealReviewService(AppealReviewMapper mapper,
                               AppealReviewSearchRepository repository) {
        super(mapper,
                repository,
                AppealReviewDocument::fromEntity,
                AppealReviewDocument::toEntity,
                AppealReview::getReviewId,
                CACHE_NAME);
        this.repository = repository;
    }

    public long countByReviewLevel(String reviewLevel) {
        return repository.findByReviewLevel(reviewLevel, page(1, 1)).getTotalHits();
    }
}
