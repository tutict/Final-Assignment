package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 标准信息检索指标：recall@k、precision@k、MRR、nDCG@k（相关性为二值）。
 * 所有方法对空期望集返回 0，调用方负责在聚合时跳过无期望文档的查询。
 */
final class RagRetrievalMetrics {

    private RagRetrievalMetrics() {
    }

    static double recallAtK(List<String> retrieved, List<String> relevant, int k) {
        if (relevant.isEmpty()) {
            return 0;
        }
        Set<String> relevantSet = new HashSet<>(relevant);
        long hits = retrieved.stream().limit(Math.max(0, k)).filter(relevantSet::contains).distinct().count();
        return (double) hits / relevantSet.size();
    }

    static double precisionAtK(List<String> retrieved, List<String> relevant, int k) {
        if (k <= 0) {
            return 0;
        }
        Set<String> relevantSet = new HashSet<>(relevant);
        long hits = retrieved.stream().limit(k).filter(relevantSet::contains).distinct().count();
        return (double) hits / k;
    }

    /** 第一个相关文档的倒数排名；无相关命中返回 0。 */
    static double reciprocalRank(List<String> retrieved, List<String> relevant) {
        Set<String> relevantSet = new HashSet<>(relevant);
        for (int index = 0; index < retrieved.size(); index++) {
            if (relevantSet.contains(retrieved.get(index))) {
                return 1.0 / (index + 1);
            }
        }
        return 0;
    }

    /** 二值相关性的 nDCG@k。 */
    static double ndcgAtK(List<String> retrieved, List<String> relevant, int k) {
        if (relevant.isEmpty() || k <= 0) {
            return 0;
        }
        Set<String> relevantSet = new HashSet<>(relevant);
        double dcg = 0;
        for (int index = 0; index < Math.min(k, retrieved.size()); index++) {
            if (relevantSet.contains(retrieved.get(index))) {
                dcg += 1.0 / (Math.log(index + 2) / Math.log(2));
            }
        }
        double idcg = 0;
        int idealHits = Math.min(k, relevantSet.size());
        for (int index = 0; index < idealHits; index++) {
            idcg += 1.0 / (Math.log(index + 2) / Math.log(2));
        }
        return idcg == 0 ? 0 : dcg / idcg;
    }

    /** 宏平均。 */
    static double mean(List<Double> values) {
        if (values.isEmpty()) {
            return 0;
        }
        return values.stream().mapToDouble(Double::doubleValue).average().orElse(0);
    }
}