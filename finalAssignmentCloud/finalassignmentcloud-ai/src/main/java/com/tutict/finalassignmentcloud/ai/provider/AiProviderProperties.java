package com.tutict.finalassignmentcloud.ai.provider;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
@ConfigurationProperties(prefix = "ai")
public class AiProviderProperties {

    private Provider provider = new Provider();
    private Ollama ollama = new Ollama();
    private OpenAiCompatible openaiCompatible = new OpenAiCompatible();

    public Provider getProvider() {
        return provider;
    }

    public void setProvider(Provider provider) {
        this.provider = provider;
    }

    public Ollama getOllama() {
        return ollama;
    }

    public void setOllama(Ollama ollama) {
        this.ollama = ollama;
    }

    public OpenAiCompatible getOpenaiCompatible() {
        return openaiCompatible;
    }

    public void setOpenaiCompatible(OpenAiCompatible openaiCompatible) {
        this.openaiCompatible = openaiCompatible;
    }

    public static class Provider {
        private String primary = "ollama";
        private String fallback = "noop";
        private Duration timeout = Duration.ofSeconds(60);
        private Duration streamingTimeout = Duration.ofSeconds(60);
        private int retryAttempts = 1;
        private int circuitBreakerFailureThreshold = 3;
        private Duration healthCacheTtl = Duration.ofSeconds(30);

        public String getPrimary() {
            return primary;
        }

        public void setPrimary(String primary) {
            this.primary = primary;
        }

        public String getFallback() {
            return fallback;
        }

        public void setFallback(String fallback) {
            this.fallback = fallback;
        }

        public Duration getTimeout() {
            return timeout;
        }

        public void setTimeout(Duration timeout) {
            this.timeout = timeout;
        }

        public Duration getStreamingTimeout() {
            return streamingTimeout;
        }

        public void setStreamingTimeout(Duration streamingTimeout) {
            this.streamingTimeout = streamingTimeout;
        }

        public int getRetryAttempts() {
            return retryAttempts;
        }

        public void setRetryAttempts(int retryAttempts) {
            this.retryAttempts = retryAttempts;
        }

        public int getCircuitBreakerFailureThreshold() {
            return circuitBreakerFailureThreshold;
        }

        public void setCircuitBreakerFailureThreshold(int circuitBreakerFailureThreshold) {
            this.circuitBreakerFailureThreshold = circuitBreakerFailureThreshold;
        }

        public Duration getHealthCacheTtl() {
            return healthCacheTtl;
        }

        public void setHealthCacheTtl(Duration healthCacheTtl) {
            this.healthCacheTtl = healthCacheTtl;
        }
    }

    public static class Ollama {
        private boolean enabled = true;
        private String baseUrl = "http://localhost:11434";
        private String chatModel = "llama3.2";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }

        public String getChatModel() {
            return chatModel;
        }

        public void setChatModel(String chatModel) {
            this.chatModel = chatModel;
        }
    }

    public static class OpenAiCompatible {
        private boolean enabled = false;
        private String baseUrl = "";
        private String apiKey = "";
        private String chatModel = "";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public String getChatModel() {
            return chatModel;
        }

        public void setChatModel(String chatModel) {
            this.chatModel = chatModel;
        }
    }
}
