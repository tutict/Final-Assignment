package finalassignmentbackend.rag.access;

import finalassignmentbackend.rag.entity.RagDocument;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RagAclPolicyTest {

    @Test
    void publicDocumentsAreVisibleToEveryone() {
        RagAclPolicy.DocumentAcl acl = RagAclPolicy.parse(document("PUBLIC", "{}"));

        assertTrue(RagAclPolicy.allows(acl, RagAccessContext.of("driver-1", Set.of("USER"))));
        assertTrue(RagAclPolicy.allows(acl, RagAccessContext.of(null, Set.of())));
    }

    @Test
    void missingScopeIsTreatedAsPublic() {
        RagAclPolicy.DocumentAcl acl = RagAclPolicy.parse(document(null, "{}"));

        assertTrue(RagAclPolicy.allows(acl, RagAccessContext.of("driver-1", Set.of("USER"))));
    }

    @Test
    void roleScopeNeedsAnIntersectingRole() {
        // RAGAS p01：仅 SUPER_ADMIN 可见的审计日志
        RagAclPolicy.DocumentAcl acl = RagAclPolicy.parse(
                document("ROLE", "{\"aclRoles\":[\"SUPER_ADMIN\"]}"));

        assertFalse(RagAclPolicy.allows(acl, RagAccessContext.of("driver-1", Set.of("USER"))));
        assertTrue(RagAclPolicy.allows(acl, RagAccessContext.of("admin-1", Set.of("SUPER_ADMIN"))));
    }

    @Test
    void userScopeNeedsTheExactUser() {
        // RAGAS p02：归属 driver-1001 的资料，当前 driver 账号不应看到
        RagAclPolicy.DocumentAcl acl = RagAclPolicy.parse(
                document("USER", "{\"aclUserIds\":[\"driver-1001\"]}"));

        assertFalse(RagAclPolicy.allows(acl, RagAccessContext.of("driver-1002", Set.of("USER"))));
        assertTrue(RagAclPolicy.allows(acl, RagAccessContext.of("driver-1001", Set.of("USER"))));
    }

    @Test
    void departmentScopeNeedsADepartmentIdentity() {
        // RAGAS p03：财务部门资料，driver 没有部门身份
        RagAclPolicy.DocumentAcl acl = RagAclPolicy.parse(
                document("DEPARTMENT", "{\"aclDepartments\":[\"finance\"]}"));

        assertFalse(RagAclPolicy.allows(acl, RagAccessContext.of("driver-1", Set.of("USER"))));
        assertTrue(RagAclPolicy.allows(acl, new RagAccessContext("fin-1", Set.of("FINANCE"), "finance")));
    }

    @Test
    void controlDocumentIsVisibleOnlyToItsOwner() {
        RagAclPolicy.DocumentAcl acl = RagAclPolicy.parse(
                document("USER", "{\"suite\":\"ragas\",\"control\":true,\"userIds\":[\"ce@ce.com\"]}"));

        assertTrue(RagAclPolicy.allows(acl, RagAccessContext.of("ce@ce.com", Set.of("USER"))));
        assertFalse(RagAclPolicy.allows(acl, RagAccessContext.of("driver-1", Set.of("USER"))));
    }

    @Test
    void metadataKeyAliasesAreAccepted() {
        assertTrue(RagAclPolicy.allows(
                RagAclPolicy.parse(document("ROLE", "{\"acl_roles\":[\"ADMIN\"]}")),
                RagAccessContext.of("admin-1", Set.of("ADMIN"))));
        assertTrue(RagAclPolicy.allows(
                RagAclPolicy.parse(document("ROLE", "{\"roles\":[\"ADMIN\"]}")),
                RagAccessContext.of("admin-1", Set.of("ADMIN"))));
        assertTrue(RagAclPolicy.allows(
                RagAclPolicy.parse(document("USER", "{\"userId\":\"ce@ce.com\"}")),
                RagAccessContext.of("ce@ce.com", Set.of("USER"))));
        assertTrue(RagAclPolicy.allows(
                RagAclPolicy.parse(document("DEPARTMENT", "{\"department\":\"finance\"}")),
                new RagAccessContext("fin-1", Set.of("FINANCE"), "finance")));
    }

    @Test
    void unknownScopeIsDenied() {
        assertFalse(RagAclPolicy.allows(
                RagAclPolicy.parse(document("SECRET", "{}")),
                RagAccessContext.of("admin-1", Set.of("SUPER_ADMIN"))));
    }

    @Test
    void brokenMetadataDeniesScopedDocuments() {
        RagAclPolicy.DocumentAcl acl = RagAclPolicy.parse(document("ROLE", "not-json"));

        assertFalse(RagAclPolicy.allows(acl, RagAccessContext.of("admin-1", Set.of("ADMIN"))));
    }

    @Test
    void nullContextOnlySeesPublicDocuments() {
        assertTrue(RagAclPolicy.allows(RagAclPolicy.parse(document("PUBLIC", "{}")), null));
        assertFalse(RagAclPolicy.allows(RagAclPolicy.parse(document("ROLE", "{}")), null));
    }

    @Test
    void accessContextNormalizesRolesAndDepartment() {
        RagAccessContext context = RagAccessContext.of(" driver-1 ", List.of("role_super_admin", "USER", " "));

        assertEquals(Set.of("SUPER_ADMIN", "USER"), context.roles());
        assertEquals("driver-1", context.userId());
        assertEquals("ALL", context.department());
    }

    @Test
    void businessRoleMapsToDepartmentAndPlainUserHasNone() {
        assertEquals("DEPARTMENT", RagAccessContext.of("fin-1", Set.of("FINANCE")).department());
        assertNull(RagAccessContext.of("driver-1", Set.of("USER")).department());
    }

    @Test
    void blankUserIdBecomesNull() {
        assertNull(RagAccessContext.of("   ", Set.of("USER")).userId());
    }

    private static RagDocument document(String aclScope, String metadataJson) {
        RagDocument document = new RagDocument();
        document.setId("doc-1");
        document.setSourceType("MANUAL");
        document.setStatus("READY");
        document.setAclScope(aclScope);
        document.setMetadataJson(metadataJson);
        return document;
    }
}
