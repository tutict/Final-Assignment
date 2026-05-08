package com.tutict.finalassignmentbackend.appeal.projection;

import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class AppealRecordProjectionAssemblerTest {

    private final AppealRecordProjectionAssembler assembler = new AppealRecordProjectionAssembler();

    @Test
    void mapsDocumentToProjection() {
        AppealRecordDocument document = document();

        AppealRecordSearchProjection projection = assembler.fromDocument(document);

        assertThat(projection.appealId()).isEqualTo(10L);
        assertThat(projection.offenseId()).isEqualTo(20L);
        assertThat(projection.appealNumber()).isEqualTo("AP-10");
        assertThat(projection.appellantName()).isEqualTo("Alice");
        assertThat(projection.appealTime()).isEqualTo(LocalDateTime.parse("2026-05-08T10:15:30"));
        assertThat(projection.sourceKey()).isEqualTo("appeal_record:10");
    }

    @Test
    void mapsEntityToProjection() {
        AppealRecord entity = entity();

        AppealRecordSearchProjection projection = assembler.fromEntity(entity);

        assertThat(projection.appealId()).isEqualTo(11L);
        assertThat(projection.offenseId()).isEqualTo(21L);
        assertThat(projection.appealNumber()).isEqualTo("AP-11");
        assertThat(projection.acceptanceStatus()).isEqualTo("ACCEPTED");
        assertThat(projection.processStatus()).isEqualTo("PENDING");
    }

    @Test
    void normalizesProjectionTextAndView() {
        AppealRecordSearchProjection projection = projectionWithWhitespace();

        AppealRecordSearchProjection normalized = assembler.normalize(projection);
        AppealRecordView view = assembler.toView(projection);

        assertThat(normalized.appealNumber()).isEqualTo("AP-12");
        assertThat(normalized.appellantName()).isEqualTo("Bob");
        assertThat(normalized.appealReason()).isEqualTo("reason");
        assertThat(view.sourceKey()).isEqualTo("appeal_record:12");
        assertThat(view.appealNumber()).isEqualTo("AP-12");
        assertThat(view.processStatus()).isEqualTo("DONE");
    }

    @Test
    void handlesNullInputsSafely() {
        assertThat(assembler.fromDocument(null)).isNull();
        assertThat(assembler.fromEntity(null)).isNull();
        assertThat(assembler.normalize(null)).isNull();
        assertThat(assembler.toView(null)).isNull();
        assertThat(assembler.toLegacyEntity(null)).isNull();
    }

    private static AppealRecordDocument document() {
        AppealRecordDocument document = new AppealRecordDocument();
        document.setAppealId(10L);
        document.setOffenseId(20L);
        document.setAppealNumber("AP-10");
        document.setAppellantName("Alice");
        document.setAppellantIdCard("ID-10");
        document.setAppealType("TYPE");
        document.setAppealReason("reason");
        document.setAppealTime(LocalDateTime.parse("2026-05-08T10:15:30"));
        document.setAcceptanceStatus("ACCEPTED");
        document.setProcessStatus("PENDING");
        return document;
    }

    private static AppealRecord entity() {
        AppealRecord entity = new AppealRecord();
        entity.setAppealId(11L);
        entity.setOffenseId(21L);
        entity.setAppealNumber("AP-11");
        entity.setAppellantName("Alice");
        entity.setAppealType("TYPE");
        entity.setAppealReason("reason");
        entity.setAcceptanceStatus("ACCEPTED");
        entity.setProcessStatus("PENDING");
        return entity;
    }

    private static AppealRecordSearchProjection projectionWithWhitespace() {
        return new AppealRecordSearchProjection(
                12L,
                22L,
                " AP-12 ",
                " Bob ",
                " ID-12 ",
                " 123456 ",
                " bob@example.com ",
                " address ",
                " type ",
                " reason ",
                LocalDateTime.parse("2026-05-08T11:15:30"),
                " evidence ",
                " urls ",
                " accepted ",
                LocalDateTime.parse("2026-05-08T12:15:30"),
                " handler ",
                " rejection ",
                " DONE ",
                LocalDateTime.parse("2026-05-08T13:15:30"),
                " result ",
                " processor ",
                LocalDateTime.parse("2026-05-08T14:15:30"),
                LocalDateTime.parse("2026-05-08T15:15:30"),
                " creator ",
                " updater ",
                null,
                " remarks "
        );
    }
}
