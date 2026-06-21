package com.tutict.finalassignmentcloud.governance.core;

import java.util.Map;

public final class GovernanceVocabulary {

    private GovernanceVocabulary() {
    }

    public interface ReadModel {
    }

    public interface WriteModel {
    }

    public interface ProjectionAssembler<S, R extends ReadModel> {

        R toReadModel(S source);
    }

    public interface RetrievalSafeView {

        Map<String, String> retrievalSafeFields();
    }
}
