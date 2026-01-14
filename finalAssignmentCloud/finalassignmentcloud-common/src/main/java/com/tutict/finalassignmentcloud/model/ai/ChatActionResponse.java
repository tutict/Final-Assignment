package com.tutict.finalassignmentcloud.model.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
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

    public ChatActionResponse() {
    }

    public ChatActionResponse(String answer, List<ChatAction> actions, boolean needConfirm) {
        this.answer = answer;
        this.actions = actions;
        this.needConfirm = needConfirm;
    }

}

