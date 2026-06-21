package com.tutict.finalassignmentbackend.rag.indexing;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.entity.offense.OffenseTypeDict;
import com.tutict.finalassignmentbackend.mapper.appeal.AppealRecordMapper;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseTypeDictMapper;
import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import com.tutict.finalassignmentbackend.rag.ingestion.AppealRecordExtractor;
import com.tutict.finalassignmentbackend.rag.ingestion.OffenseTypeExtractor;
import com.tutict.finalassignmentbackend.rag.ingestion.RagSourceExtractor;
import com.tutict.finalassignmentbackend.rag.service.RagIndexingService;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
public class RagBackfillJob {

    private final OffenseTypeDictMapper offenseTypeDictMapper;
    private final AppealRecordMapper appealRecordMapper;
    private final OffenseTypeExtractor offenseTypeExtractor;
    private final AppealRecordExtractor appealRecordExtractor;
    private final RagIndexingService indexingService;
    private final RagProperties properties;

    public RagBackfillJob(
            OffenseTypeDictMapper offenseTypeDictMapper,
            AppealRecordMapper appealRecordMapper,
            OffenseTypeExtractor offenseTypeExtractor,
            AppealRecordExtractor appealRecordExtractor,
            RagIndexingService indexingService,
            RagProperties properties
    ) {
        this.offenseTypeDictMapper = offenseTypeDictMapper;
        this.appealRecordMapper = appealRecordMapper;
        this.offenseTypeExtractor = offenseTypeExtractor;
        this.appealRecordExtractor = appealRecordExtractor;
        this.indexingService = indexingService;
        this.properties = properties;
    }

    public RagBackfillResult runNextBatch() {
        return runBatch(1, properties.getIndexing().getBatchSize());
    }

    public RagBackfillResult runBatch(int page, int size) {
        if (!properties.isEnabled() || !properties.getIndexing().isEnabled()) {
            return new RagBackfillResult(0, 0, false, false);
        }

        int effectivePage = Math.max(1, page);
        int effectiveSize = Math.max(1, size);
        Page<OffenseTypeDict> offensePage = new Page<>(effectivePage, effectiveSize);
        offenseTypeDictMapper.selectPage(offensePage, new QueryWrapper<>());
        Page<AppealRecord> appealPage = new Page<>(effectivePage, effectiveSize);
        appealRecordMapper.selectPage(appealPage, new QueryWrapper<>());

        BatchCounter counter = new BatchCounter();
        process(offensePage.getRecords(), offenseTypeExtractor, counter);
        process(appealPage.getRecords(), appealRecordExtractor, counter);

        boolean hasMore = offensePage.getRecords().size() == effectiveSize
                || appealPage.getRecords().size() == effectiveSize;
        return new RagBackfillResult(counter.processed, counter.failed, hasMore, true);
    }

    public RagBackfillRunResult runBatches(int startPage, int size, int maxPages) {
        if (!properties.isEnabled() || !properties.getIndexing().isEnabled()) {
            return new RagBackfillRunResult(0, 0, 0, false, false);
        }
        int effectiveStartPage = Math.max(1, startPage);
        int effectiveMaxPages = Math.min(Math.max(1, maxPages), 100);
        int processed = 0;
        int failed = 0;
        boolean hasMore = false;
        int pages = 0;
        for (int offset = 0; offset < effectiveMaxPages; offset++) {
            RagBackfillResult result = runBatch(effectiveStartPage + offset, size);
            pages++;
            processed += result.processedDocuments();
            failed += result.failedDocuments();
            hasMore = result.hasMore();
            if (!hasMore) {
                break;
            }
        }
        return new RagBackfillRunResult(processed, failed, pages, hasMore, true);
    }

    private <T> void process(List<T> records, RagSourceExtractor<T> extractor, BatchCounter counter) {
        for (T record : records) {
            try {
                indexingService.index(extractor.extract(record));
                counter.processed++;
            } catch (RuntimeException error) {
                counter.failed++;
            }
        }
    }

    private static final class BatchCounter {
        private int processed;
        private int failed;
    }

    public record RagBackfillResult(
            int processedDocuments,
            int failedDocuments,
            boolean hasMore,
            boolean enabled
    ) {
    }

    public record RagBackfillRunResult(
            int processedDocuments,
            int failedDocuments,
            int processedPages,
            boolean hasMore,
            boolean enabled
    ) {
    }
}
