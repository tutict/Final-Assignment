package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.lang.Nullable;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Function;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

/**
 * Reusable CRUD support that keeps MySQL (via MyBatis) and Elasticsearch in sync.
 * This consolidates the patterns already established in {@link DriverInformationService}
 * and {@link VehicleInformationService} while remaining lightweight for new services.
 *
 * @param <E>  entity type handled by MyBatis
 * @param <D>  Elasticsearch document type
 * @param <ID> identifier type
 */
public abstract class AbstractElasticsearchCrudService<E, D, ID> {

    private final Logger log = Logger.getLogger(getClass().getName());
    private final BaseMapper<E> mapper;
    private final ElasticsearchRepository<D, ID> repository;
    private final Function<E, D> entityToDocument;
    private final Function<D, E> documentToEntity;
    private final Function<E, ID> idExtractor;
    private final String cacheName;

    @Nullable
    private CacheManager cacheManager;

    protected AbstractElasticsearchCrudService(BaseMapper<E> mapper,
                                               ElasticsearchRepository<D, ID> repository,
                                               Function<E, D> entityToDocument,
                                               Function<D, E> documentToEntity,
                                               Function<E, ID> idExtractor) {
        this(mapper, repository, entityToDocument, documentToEntity, idExtractor, null);
    }

    protected AbstractElasticsearchCrudService(BaseMapper<E> mapper,
                                               ElasticsearchRepository<D, ID> repository,
                                               Function<E, D> entityToDocument,
                                               Function<D, E> documentToEntity,
                                               Function<E, ID> idExtractor,
                                               @Nullable String cacheName) {
        this.mapper = Objects.requireNonNull(mapper, "mapper must not be null");
        this.repository = Objects.requireNonNull(repository, "repository must not be null");
        this.entityToDocument = Objects.requireNonNull(entityToDocument, "entityToDocument must not be null");
        this.documentToEntity = Objects.requireNonNull(documentToEntity, "documentToEntity must not be null");
        this.idExtractor = Objects.requireNonNull(idExtractor, "idExtractor must not be null");
        this.cacheName = (cacheName != null && !cacheName.isBlank())
                ? cacheName
                : defaultCacheName();
    }

    @Autowired(required = false)
    public void setCacheManager(@Nullable CacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    @Transactional
    public E create(E entity) {
        validateForCreate(entity);
        mapper.insert(entity);
        ID id = requireId(entity);
        runAfterCommitOrNow(() -> {
            evictCache();
            syncDocument(entity);
            cachePut(entity);
        });
        evictCacheKey(id);
        return entity;
    }

    @Transactional
    public E update(E entity) {
        validateForUpdate(entity);
        int rows = mapper.updateById(entity);
        if (rows == 0) {
            throw new IllegalStateException("No records updated for id=" + requireId(entity));
        }
        runAfterCommitOrNow(() -> {
            evictCache();
            syncDocument(entity);
            cachePut(entity);
        });
        return entity;
    }

    @Transactional
    public void delete(ID id) {
        validateId(id);
        int rows = mapper.deleteById(id);
        if (rows == 0) {
            throw new IllegalStateException("No records deleted for id=" + id);
        }
        runAfterCommitOrNow(() -> {
            repository.deleteById(id);
            evictCache();
            evictCacheKey(id);
        });
    }

    @Transactional(readOnly = true)
    public E findById(ID id) {
        validateId(id);

        E cached = cacheGet(id);
        if (cached != null) {
            return cached;
        }

        Optional<D> fromIndex = repository.findById(id);
        if (fromIndex.isPresent()) {
            E entity = documentToEntity.apply(fromIndex.get());
            cachePut(entity);
            return entity;
        }

        E entity = mapper.selectById(id);
        if (entity != null) {
            syncDocument(entity);
            cachePut(entity);
        }
        return entity;
    }

    @Transactional(readOnly = true)
    public List<E> findAll() {
        List<E> fromIndex = StreamSupport.stream(repository.findAll().spliterator(), false)
                .map(documentToEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            fromIndex.forEach(this::cachePut);
            return fromIndex;
        }

        List<E> fromDb = mapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    protected List<E> mapHits(@Nullable SearchHits<D> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(SearchHit::getContent)
                .filter(Objects::nonNull)
                .map(documentToEntity)
                .collect(Collectors.toList());
    }

    protected Pageable page(int page, int size) {
        validatePagination(page, size);
        return PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    protected void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page and size must be greater than zero");
        }
    }

    protected void requirePositive(Number number, String fieldName) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException(fieldName + " must be greater than zero");
        }
    }

    protected Logger logger() {
        return log;
    }

    protected BaseMapper<E> mapper() {
        return mapper;
    }

    protected ElasticsearchRepository<D, ID> repository() {
        return repository;
    }

    protected void syncToIndexAfterCommit(E entity) {
        if (entity == null) {
            return;
        }
        runAfterCommitOrNow(() -> {
            syncDocument(entity);
            cachePut(entity);
        });
    }

    protected void syncBatchToIndexAfterCommit(@Nullable Collection<E> entities) {
        if (entities == null || entities.isEmpty()) {
            return;
        }
        runAfterCommitOrNow(() -> {
            List<D> documents = entities.stream()
                    .filter(Objects::nonNull)
                    .map(entityToDocument)
                    .filter(Objects::nonNull)
                    .collect(Collectors.toList());
            if (!documents.isEmpty()) {
                repository.saveAll(documents);
            }
            entities.forEach(this::cachePut);
        });
    }

    protected void evictCache() {
        Cache cache = cache();
        if (cache != null) {
            cache.clear();
        }
    }

    protected String cacheName() {
        return cacheName;
    }

    private void validateForCreate(E entity) {
        Objects.requireNonNull(entity, "Entity must not be null");
    }

    private void validateForUpdate(E entity) {
        validateForCreate(entity);
        requireId(entity);
    }

    private void validateId(ID id) {
        Objects.requireNonNull(id, "ID must not be null");
        if (id instanceof Number number && number.longValue() <= 0) {
            throw new IllegalArgumentException("ID must be greater than zero");
        }
    }

    private ID requireId(E entity) {
        ID id = idExtractor.apply(entity);
        if (id == null) {
            throw new IllegalArgumentException("Entity ID must not be null");
        }
        return id;
    }

    private void cachePut(@Nullable E entity) {
        Cache cache = cache();
        if (cache == null || entity == null) {
            return;
        }
        cache.put(requireId(entity), entity);
    }

    @SuppressWarnings("unchecked")
    private E cacheGet(ID id) {
        Cache cache = cache();
        if (cache == null || id == null) {
            return null;
        }
        Cache.ValueWrapper wrapper = cache.get(id);
        return wrapper != null ? (E) wrapper.get() : null;
    }

    private void evictCacheKey(@Nullable ID id) {
        Cache cache = cache();
        if (cache != null && id != null) {
            cache.evict(id);
        }
    }

    private Cache cache() {
        return cacheManager != null ? cacheManager.getCache(cacheName) : null;
    }

    private void syncDocument(E entity) {
        D document = entityToDocument.apply(entity);
        if (document != null) {
            repository.save(document);
        }
    }

    private void runAfterCommitOrNow(@Nullable Runnable action) {
        if (action == null) {
            return;
        }
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    safeRun(action);
                }
            });
        } else {
            safeRun(action);
        }
    }

    private void safeRun(Runnable action) {
        try {
            action.run();
        } catch (Exception ex) {
            log.log(Level.WARNING, "Failed to execute post-transaction action", ex);
        }
    }

    private String defaultCacheName() {
        String simpleName = getClass().getSimpleName();
        if (simpleName.endsWith("Service")) {
            simpleName = simpleName.substring(0, simpleName.length() - "Service".length());
        }
        if (simpleName.isEmpty()) {
            return "defaultCache";
        }
        return Character.toLowerCase(simpleName.charAt(0)) + simpleName.substring(1) + "Cache";
    }
}
