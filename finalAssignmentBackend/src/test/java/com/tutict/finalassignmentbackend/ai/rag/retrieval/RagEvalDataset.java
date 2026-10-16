package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.List;

/**
 * 离线 RAG 评测金标集：一段受控语料 + 一组 query→期望文档。
 *
 * <p>评测在 CI 中运行，不依赖 Elasticsearch / 真实 embedding 服务：语料与查询都来自
 * {@code src/test/resources/rag-eval/golden-set.json}，检索后端为内存实现。这样可以在
 * 不引入外部依赖的前提下，对生产检索链路（BM25 + 向量融合、ACL 过滤、rerank）做回归门禁。
 */
record RagEvalDataset(List<EvalChunk> corpus, List<EvalQuery> queries) {

    RagEvalDataset {
        corpus = corpus == null ? List.of() : List.copyOf(corpus);
        queries = queries == null ? List.of() : List.copyOf(queries);
    }

    static RagEvalDataset load(String classpathResource) {
        ObjectMapper mapper = new ObjectMapper();
        try (InputStream in = RagEvalDataset.class.getResourceAsStream(classpathResource)) {
            if (in == null) {
                throw new IllegalStateException("Missing evaluation resource: " + classpathResource);
            }
            return mapper.readValue(in, RagEvalDataset.class);
        } catch (IOException error) {
            throw new UncheckedIOException("Failed to load RAG evaluation set " + classpathResource, error);
        }
    }

    /** 参与质量指标（recall/MRR/nDCG）计算的查询：期望文档非空。 */
    List<EvalQuery> qualityQueries() {
        return queries.stream().filter(query -> !query.relevantChunkIds().isEmpty()).toList();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record EvalChunk(
            String chunkId,
            String documentId,
            String title,
            String content,
            String sourceType,
            String sourceField,
            String route,
            String aclScope,
            List<String> aclRoles,
            List<String> aclUserIds,
            List<String> aclDepartments
    ) {
        EvalChunk {
            aclScope = aclScope == null || aclScope.isBlank() ? "PUBLIC" : aclScope;
            aclRoles = aclRoles == null ? List.of() : List.copyOf(aclRoles);
            aclUserIds = aclUserIds == null ? List.of() : List.copyOf(aclUserIds);
            aclDepartments = aclDepartments == null ? List.of() : List.copyOf(aclDepartments);
        }

        String searchableText() {
            return (title == null ? "" : title) + " " + (content == null ? "" : content);
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record EvalQuery(
            String id,
            String query,
            String userId,
            List<String> roles,
            String department,
            List<String> relevantChunkIds,
            List<String> mustNotReturn
    ) {
        EvalQuery {
            roles = roles == null ? List.of() : List.copyOf(roles);
            relevantChunkIds = relevantChunkIds == null ? List.of() : List.copyOf(relevantChunkIds);
            mustNotReturn = mustNotReturn == null ? List.of() : List.copyOf(mustNotReturn);
        }

        AclFilterService.AccessContext accessContext() {
            return new AclFilterService.AccessContext(userId, new java.util.LinkedHashSet<>(roles), department);
        }
    }
}