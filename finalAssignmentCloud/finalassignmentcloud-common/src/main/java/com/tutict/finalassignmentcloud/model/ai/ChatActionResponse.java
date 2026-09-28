package com.tutict.finalassignmentcloud.model.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Setter
@Getter
@JsonIgnoreProperties(ignoreUnknown = true)
public class ChatActionResponse {

    private String answer;
    private List<ChatAction> actions;
    private boolean needConfirm;

    @Getter(AccessLevel.NONE)
    @Setter(AccessLevel.NONE)
    @JsonProperty("isFallback")
    private boolean fallback;

    @JsonProperty("isFallback")
    public boolean isFallback() {
        return fallback;
    }

    public void setFallback(boolean fallback) {
        this.fallback = fallback;
    }

    public ChatActionResponse() {
    }

    public ChatActionResponse(String answer, List<ChatAction> actions, boolean needConfirm) {
        this.answer = answer;
        this.actions = actions;
        this.needConfirm = needConfirm;
    }

}

