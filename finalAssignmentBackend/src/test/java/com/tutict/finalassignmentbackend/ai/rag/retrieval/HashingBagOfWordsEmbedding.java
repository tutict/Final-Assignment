package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import java.util.List;

/**
 * 评测用确定性 embedding：hashing bag-of-words。
 *
 * <p>把分词结果哈希到固定维度并做 L2 归一化，使余弦相似度与词面重合度成正比。它替代生产
 * 环境中的真实 embedding 模型，让离线评测在无网络、无模型下载的前提下仍能产生稳定的向量
 * 相似度信号——评测关注的是融合/重排/ACL 链路，而非某个具体 embedding 模型的质量。
 */
final class HashingBagOfWordsEmbedding implements EmbeddingProvider {

    private final int dimensions;

    HashingBagOfWordsEmbedding(int dimensions) {
        this.dimensions = Math.max(1, dimensions);
    }

    @Override
    public String providerName() {
        return "eval-hashing-bow";
    }

    @Override
    public int dimensions() {
        return dimensions;
    }

    @Override
    public float[] embed(String text) {
        float[] vector = new float[dimensions];
        List<String> tokens = EvalTokenizer.tokens(text);
        for (String token : tokens) {
            int index = Math.floorMod(mix(token.hashCode()), dimensions);
            vector[index] += 1f;
        }
        double sum = 0;
        for (float value : vector) {
            sum += value * value;
        }
        double norm = Math.sqrt(sum);
        if (norm > 0) {
            for (int i = 0; i < vector.length; i++) {
                vector[i] = (float) (vector[i] / norm);
            }
        }
        return vector;
    }

    /** 64-bit 风格的混合，缓解短字符串 hashCode 的分布偏差，减少哈希碰撞导致的伪相似。 */
    private static int mix(int value) {
        int mixed = value * 0x9E3779B1;
        mixed ^= mixed >>> 16;
        mixed *= 0x85EBCA6B;
        mixed ^= mixed >>> 13;
        return mixed;
    }
}