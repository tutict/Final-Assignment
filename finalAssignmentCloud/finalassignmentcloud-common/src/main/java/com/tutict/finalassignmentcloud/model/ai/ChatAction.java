package com.tutict.finalassignmentcloud.model.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
@JsonIgnoreProperties(ignoreUnknown = true)
public class ChatAction {

    private String type;
    private String label;
    private String target;
    private String value;

    public ChatAction() {
    }

    public ChatAction(String type, String label, String target, String value) {
        this.type = type;
        this.label = label;
        this.target = target;
        this.value = value;
    }

}

