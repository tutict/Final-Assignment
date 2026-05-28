package com.tutict.finalassignmentbackend.ai.rag.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "rag.retrieval")
public class RagRetrievalProperties {

    private boolean enabled = false;
    private int topK = 10;
    private double vectorWeight = 0.6;
    private double bm25Weight = 0.4;
    private double minScore = 0.2;
    private int candidateMultiplier = 3;
    private int rrfRankConstant = 60;
    private boolean rerankEnabled = true;
    private double rerankLexicalWeight = 0.15;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public int getTopK() {
        return topK;
    }

    public void setTopK(int topK) {
        this.topK = topK;
    }

    public double getVectorWeight() {
        return vectorWeight;
    }

    public void setVectorWeight(double vectorWeight) {
        this.vectorWeight = vectorWeight;
    }

    public double getBm25Weight() {
        return bm25Weight;
    }

    public void setBm25Weight(double bm25Weight) {
        this.bm25Weight = bm25Weight;
    }

    public double getMinScore() {
        return minScore;
    }

    public void setMinScore(double minScore) {
        this.minScore = minScore;
    }

    public int getCandidateMultiplier() {
        return candidateMultiplier;
    }

    public void setCandidateMultiplier(int candidateMultiplier) {
        this.candidateMultiplier = candidateMultiplier;
    }

    public int getRrfRankConstant() {
        return rrfRankConstant;
    }

    public void setRrfRankConstant(int rrfRankConstant) {
        this.rrfRankConstant = rrfRankConstant;
    }

    public boolean isRerankEnabled() {
        return rerankEnabled;
    }

    public void setRerankEnabled(boolean rerankEnabled) {
        this.rerankEnabled = rerankEnabled;
    }

    public double getRerankLexicalWeight() {
        return rerankLexicalWeight;
    }

    public void setRerankLexicalWeight(double rerankLexicalWeight) {
        this.rerankLexicalWeight = rerankLexicalWeight;
    }
}
