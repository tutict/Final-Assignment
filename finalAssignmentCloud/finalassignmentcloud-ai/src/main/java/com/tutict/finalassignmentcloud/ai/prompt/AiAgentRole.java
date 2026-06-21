package com.tutict.finalassignmentcloud.ai.prompt;

public enum AiAgentRole {
    DRIVER("driver"),
    ADMIN("admin"),
    SUPER_ADMIN("super_admin");

    private final String policyFileName;

    AiAgentRole(String policyFileName) {
        this.policyFileName = policyFileName;
    }

    public String policyFileName() {
        return policyFileName;
    }
}
