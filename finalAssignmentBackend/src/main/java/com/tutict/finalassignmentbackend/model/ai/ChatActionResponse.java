package com.tutict.finalassignmentbackend.model.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public class ChatActionResponse {

    private String answer;
    private List<ChatAction> actions;
    private boolean needConfirm;
    @JsonProperty("isFallback")
    private boolean fallback;

    public ChatActionResponse() {
    }

    public ChatActionResponse(String answer, List<ChatAction> actions, boolean needConfirm) {
        this.answer = answer;
        this.actions = actions;
        this.needConfirm = needConfirm;
    }

    public String getAnswer() {
        return answer;
    }

    public void setAnswer(String answer) {
        this.answer = answer;
    }

    public List<ChatAction> getActions() {
        return actions;
    }

    public void setActions(List<ChatAction> actions) {
        this.actions = actions;
    }

    public boolean isNeedConfirm() {
        return needConfirm;
    }

    @JsonProperty("isFallback")
    public boolean isFallback() {
        return fallback;
    }

    public void setFallback(boolean fallback) {
        this.fallback = fallback;
    }

    public void setNeedConfirm(boolean needConfirm) {
        this.needConfirm = needConfirm;
    }
}
