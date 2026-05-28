package finalassignmentbackend.service;

import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Set;

@ApplicationScoped
public class SearchService {

    private static final Set<String> ALLOWED_INDEXES = Set.of("offense_index", "driver_index");

    @ConfigProperty(name = "elasticsearch.host", defaultValue = "http://localhost:9200")
    String elasticsearchHost;

    private final HttpClient httpClient = HttpClient.newHttpClient();

    public String search(String query, String indexName) throws Exception {
        String normalizedQuery = requireText(query, "Query string");
        String normalizedIndex = requireText(indexName, "Index name");
        if (!ALLOWED_INDEXES.contains(normalizedIndex)) {
            throw new IllegalArgumentException("Invalid index name: " + normalizedIndex);
        }

        String endpoint = elasticsearchHost.replaceAll("/+$", "") + "/" + normalizedIndex + "/_search";
        String requestBody = """
                {
                  "query": {
                    "query_string": {
                      "query": "__QUERY__"
                    }
                  }
                }
                """.replace("__QUERY__", escapeJson(normalizedQuery));

        HttpRequest request = HttpRequest.newBuilder(URI.create(endpoint))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestBody, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException("Elasticsearch search failed with status " + response.statusCode());
        }
        return response.body();
    }

    private String requireText(String value, String fieldName) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException(fieldName + " cannot be null or empty");
        }
        return value.trim();
    }

    private String escapeJson(String value) {
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "\\r")
                .replace("\n", "\\n");
    }
}
