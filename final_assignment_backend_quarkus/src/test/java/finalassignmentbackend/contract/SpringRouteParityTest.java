package finalassignmentbackend.contract;

import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Characterization test that locks in the route-contract gap between the
 * Spring Boot monolith ({@code finalAssignmentBackend}) and this Quarkus port.
 *
 * <p>It mirrors the Go backend's {@code spring_coverage_test.go}: it scans
 * Spring {@code @RequestMapping}/{@code @GetMapping}... controller mappings and
 * the JAX-RS {@code @Path}/{@code @GET}... mappings declared here, then compares
 * the two route sets (HTTP method + path, with {@code {var}} path parameters
 * preserved verbatim).
 *
 * <p>The Quarkus port is intentionally incomplete (no RAG, no WebSocket ticket,
 * a trimmed AI-chat surface, etc.), so the current gaps are recorded as a
 * baseline snapshot. The test fails when the gap set <em>changes</em>:
 * <ul>
 *   <li>a Spring route that used to be covered is now missing here (regression), or</li>
 *   <li>a previously-missing route was ported (the snapshot must be updated).</li>
 * </ul>
 * This keeps the gap explicit and prevents silent drift, the way the Go parity
 * test does for the Go backend.
 *
 * <p>If the Spring source tree is not present (e.g. building this module in
 * isolation), the test is skipped via {@link Assumptions#abort(String)}.
 */
class SpringRouteParityTest {

    // --- Spring (Spring Web MVC) annotation handling -----------------------

    private static final Pattern SPRING_CLASS_PATH = Pattern.compile(
            "@RequestMapping\\s*\\(\\s*(?:(?:value|path)\\s*=\\s*)?\"([^\"]+)\"");

    private static final Pattern SPRING_METHOD_MAPPING = Pattern.compile(
            "@(GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)\\b\\s*(?:\\(([^)]*)\\))?",
            Pattern.DOTALL);

    private static final Pattern SPRING_SUBPATH = Pattern.compile(
            "(?:value|path)\\s*=\\s*\"([^\"]+)\"|\"([^\"]+)\"");

    // --- Quarkus (JAX-RS) annotation handling ------------------------------

    private static final Pattern JAXRS_CLASS_PATH = Pattern.compile(
            "@Path\\s*\\(\\s*\"([^\"]+)\"\\s*\\)");

    private static final Pattern JAXRS_METHOD_VERB = Pattern.compile(
            "@(GET|POST|PUT|DELETE|PATCH)\\b");

    private static final Pattern JAXRS_SUBPATH = Pattern.compile(
            "@Path\\s*\\(\\s*\"([^\"]+)\"\\s*\\)");

    /**
     * Baseline snapshot of Spring routes that are NOT (yet) exposed by the
     * Quarkus port. When a route here gets ported, remove it from this set;
     * when a new Spring route is missing here, add it (or port it).
     */
    private static final Set<String> KNOWN_SPRING_ROUTES_MISSING_FROM_QUARKUS = Set.of(
            "DELETE /api/rag/admin/documents/{documentId}",
            "GET /api/ai/chat/actions",
            "GET /api/appeals/my",
            "GET /api/auth/me",
            "GET /api/drivers/search",
            "GET /api/fines/driver/{driverId}",
            "GET /api/offenses/{offenseId}/details",
            "GET /api/payments/driver/{driverId}",
            "GET /api/rag/admin/documents",
            "GET /api/rag/admin/overview",
            "GET /api/vehicles/autocomplete",
            "GET /api/vehicles/drivers/{driverId}/records",
            "POST /api/ai/chat/stream",
            "POST /api/auth/logout",
            "POST /api/auth/refresh",
            "POST /api/payments/driver/{driverId}",
            "POST /api/rag/admin/backfill",
            "POST /api/rag/admin/backfill/run",
            "POST /api/rag/admin/documents/manual",
            "POST /api/rag/admin/documents/upload",
            "POST /api/rag/admin/embedding/requeue",
            "POST /api/rag/admin/embedding/run",
            "POST /api/rag/admin/index/migrate",
            "POST /api/rag/query",
            "POST /api/ws-ticket");

    /**
     * Baseline snapshot of Quarkus routes that have no Spring counterpart.
     */
    private static final Set<String> KNOWN_QUARKUS_ROUTES_NOT_IN_SPRING = Set.of(
            "GET /search");

    @Test
    void springRoutesMissingFromQuarkusMatchesBaseline() throws IOException {
        Path springRoot = resolveSpringSourceRoot();
        Set<String> spring = loadSpringRoutes(springRoot);
        Set<String> quarkus = loadQuarkusRoutes();

        Set<String> actual = new TreeSet<>(spring);
        actual.removeAll(quarkus);

        assertSnapshotMatches("Spring routes missing from Quarkus",
                KNOWN_SPRING_ROUTES_MISSING_FROM_QUARKUS, actual);
    }

    @Test
    void quarkusRoutesNotInSpringMatchesBaseline() throws IOException {
        Path springRoot = resolveSpringSourceRoot();
        Set<String> spring = loadSpringRoutes(springRoot);
        Set<String> quarkus = loadQuarkusRoutes();

        Set<String> actual = new TreeSet<>(quarkus);
        actual.removeAll(spring);

        assertSnapshotMatches("Quarkus routes not present in Spring",
                KNOWN_QUARKUS_ROUTES_NOT_IN_SPRING, actual);
    }

    // --- assertions --------------------------------------------------------

    private static void assertSnapshotMatches(String label, Set<String> baseline, Set<String> actual) {
        Set<String> newlyMissing = new TreeSet<>(actual);
        newlyMissing.removeAll(baseline);

        Set<String> portedOrRemoved = new TreeSet<>(baseline);
        portedOrRemoved.removeAll(actual);

        if (newlyMissing.isEmpty() && portedOrRemoved.isEmpty()) {
            return;
        }

        StringBuilder msg = new StringBuilder(label + " snapshot is stale.\n");
        if (!newlyMissing.isEmpty()) {
            msg.append("  New gap (port the route, or add to the baseline snapshot):\n");
            newlyMissing.forEach(r -> msg.append("    \"").append(r).append("\",\n"));
        }
        if (!portedOrRemoved.isEmpty()) {
            msg.append("  Resolved gap (remove from the baseline snapshot):\n");
            portedOrRemoved.forEach(r -> msg.append("    \"").append(r).append("\",\n"));
        }
        msg.append("\nFull actual set (").append(actual.size()).append("):\n");
        actual.forEach(r -> msg.append("  ").append(r).append("\n"));
        assertEquals(baseline, actual, msg.toString());
    }

    // --- Spring route extraction ------------------------------------------

    private static Set<String> loadSpringRoutes(Path root) throws IOException {
        Map<String, String> routes = new TreeMap<>();
        Files.walkFileTree(root, new SimpleFileVisitor<>() {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                String name = file.getFileName().toString();
                if (!name.endsWith("Controller.java")) {
                    return FileVisitResult.CONTINUE;
                }
                String src = Files.readString(file);
                Matcher baseM = SPRING_CLASS_PATH.matcher(src);
                if (!baseM.find()) {
                    return FileVisitResult.CONTINUE;
                }
                String base = baseM.group(1);

                Matcher mm = SPRING_METHOD_MAPPING.matcher(src);
                while (mm.find()) {
                    String method = springMethod(mm.group(1));
                    if (method == null) {
                        continue;
                    }
                    String sub = "";
                    String body = mm.group(2); // may be null for bare @GetMapping
                    if (body != null) {
                        Matcher sp = SPRING_SUBPATH.matcher(body);
                        if (sp.find()) {
                            sub = sp.group(1) != null ? sp.group(1) : sp.group(2);
                        }
                    }
                    routes.putIfAbsent(method + " " + joinPath(base, sub), name);
                }
                return FileVisitResult.CONTINUE;
            }
        });
        if (routes.isEmpty()) {
            throw new IllegalStateException("no Spring controller routes found under " + root);
        }
        return routes.keySet();
    }

    private static String springMethod(String mapping) {
        return switch (mapping) {
            case "GetMapping" -> "GET";
            case "PostMapping" -> "POST";
            case "PutMapping" -> "PUT";
            case "DeleteMapping" -> "DELETE";
            case "PatchMapping" -> "PATCH";
            default -> null;
        };
    }

    // --- Quarkus (JAX-RS) route extraction --------------------------------

    private static Set<String> loadQuarkusRoutes() throws IOException {
        Path root = Paths.get(System.getProperty("user.dir")).resolve("src/main/java");
        Map<String, String> routes = new TreeMap<>();
        Files.walkFileTree(root, new SimpleFileVisitor<>() {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                String name = file.getFileName().toString();
                if (!name.endsWith("Controller.java") && !name.endsWith("Resource.java")) {
                    return FileVisitResult.CONTINUE;
                }
                String src = Files.readString(file);
                Matcher baseM = JAXRS_CLASS_PATH.matcher(src);
                if (!baseM.find()) {
                    return FileVisitResult.CONTINUE;
                }
                String base = baseM.group(1);

                String[] lines = src.split("\n", -1);
                for (int i = 0; i < lines.length; i++) {
                    Matcher vm = JAXRS_METHOD_VERB.matcher(lines[i]);
                    if (!vm.find()) {
                        continue;
                    }
                    String method = vm.group(1);
                    String sub = "";
                    // @Path("sub") conventionally follows the verb on the next line(s);
                    // stop at the next verb so we don't grab the following method's path.
                    for (int j = i + 1; j < Math.min(i + 6, lines.length); j++) {
                        if (JAXRS_METHOD_VERB.matcher(lines[j]).find()) {
                            break;
                        }
                        Matcher sp = JAXRS_SUBPATH.matcher(lines[j]);
                        if (sp.find()) {
                            sub = sp.group(1);
                            break;
                        }
                    }
                    routes.putIfAbsent(method + " " + joinPath(base, sub), name);
                }
                return FileVisitResult.CONTINUE;
            }
        });
        if (routes.isEmpty()) {
            throw new IllegalStateException("no Quarkus controller routes found under " + root);
        }
        return routes.keySet();
    }

    // --- helpers ----------------------------------------------------------

    private static String joinPath(String base, String sub) {
        String path = stripTrailingSlash(base);
        if (sub != null && !sub.isEmpty()) {
            path += "/" + stripLeadingSlash(sub);
        }
        return path.isEmpty() ? "/" : path;
    }

    private static String stripTrailingSlash(String s) {
        return s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }

    private static String stripLeadingSlash(String s) {
        return s.startsWith("/") ? s.substring(1) : s;
    }

    private static Path resolveSpringSourceRoot() {
        String envRoot = System.getenv("SPRING_SOURCE_ROOT");
        List<Path> candidates = new ArrayList<>();
        if (envRoot != null && !envRoot.isBlank()) {
            candidates.add(Paths.get(envRoot));
        }
        // When running via ./gradlew test from final_assignment_backend_quarkus/
        Path cwd = Paths.get(System.getProperty("user.dir"));
        candidates.add(cwd.resolve("../finalAssignmentBackend/src/main/java"));
        candidates.add(cwd.resolve("../../finalAssignmentBackend/src/main/java"));

        for (Path c : candidates) {
            Path normalized = c.normalize();
            if (Files.isDirectory(normalized)) {
                return normalized;
            }
        }
        Assumptions.abort("Spring Boot source tree is unavailable; checked " + candidates);
        return null;
    }
}
