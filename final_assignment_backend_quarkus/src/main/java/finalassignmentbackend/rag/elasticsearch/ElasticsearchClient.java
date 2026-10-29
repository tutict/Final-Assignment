package finalassignmentbackend.rag.elasticsearch;

import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.json.JsonReader;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.io.StringReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Optional;

/**
 * Elasticsearch HTTP 客户端。
 *
 * <p>仓库不引入官方 ES 客户端依赖：检索与索引只用少量 REST 端点，JDK {@link HttpClient}
 * 加 JSON-P 足够，也避免为 RAG 引入新的依赖面。
 */
@ApplicationScoped
public class ElasticsearchClient {

    @ConfigProperty(name = "elasticsearch.host", defaultValue = "http://localhost:9200")
    String host;

    @ConfigProperty(name = "rag.elasticsearch.timeout", defaultValue = "10s")
    Duration timeout;

    private final HttpClient httpClient;

    public ElasticsearchClient() {
        this(HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build());
    }

    ElasticsearchClient(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

    public JsonObject getJson(String path) {
        Response response = execute("GET", path, null);
        if (response.status() >= 400) {
            throw new ElasticsearchException("Elasticsearch GET failed for " + path, response.status(), response.body());
        }
        return parse(response);
    }

    /** 404 视为「资源不存在」，其余错误状态仍然抛出。 */
    public Optional<JsonObject> findJson(String path) {
        Response response = execute("GET", path, null);
        if (response.status() == 404) {
            return Optional.empty();
        }
        if (response.status() >= 400) {
            throw new ElasticsearchException("Elasticsearch GET failed for " + path, response.status(), response.body());
        }
        return Optional.of(parse(response));
    }

    public JsonObject postJson(String path, JsonObject body) {
        return write("POST", path, body);
    }

    public JsonObject putJson(String path, JsonObject body) {
        return write("PUT", path, body);
    }

    public JsonObject deleteJson(String path) {
        return write("DELETE", path, null);
    }

    /** HEAD 探测：资源存在返回 true。 */
    public boolean exists(String path) {
        Response response = execute("HEAD", path, null);
        if (response.status() == 404) {
            return false;
        }
        if (response.status() >= 400) {
            throw new ElasticsearchException("Elasticsearch HEAD failed for " + path, response.status(), response.body());
        }
        return true;
    }

    private JsonObject write(String method, String path, JsonObject body) {
        Response response = execute(method, path, body);
        if (response.status() >= 400) {
            throw new ElasticsearchException("Elasticsearch " + method + " failed for " + path,
                    response.status(), response.body());
        }
        return parse(response);
    }

    private Response execute(String method, String path, JsonObject body) {
        String endpoint = baseUri() + normalizePath(path);
        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(endpoint))
                .timeout(timeout == null ? Duration.ofSeconds(10) : timeout)
                .header("Accept", "application/json");
        if (body == null) {
            builder.method(method, HttpRequest.BodyPublishers.noBody());
        } else {
            builder.header("Content-Type", "application/json; charset=utf-8");
            builder.method(method, HttpRequest.BodyPublishers.ofString(body.toString(), StandardCharsets.UTF_8));
        }
        try {
            HttpResponse<String> response = httpClient.send(builder.build(),
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            String responseBody = response.body() == null ? "" : response.body();
            return new Response(response.statusCode(), responseBody);
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            throw new ElasticsearchException("Elasticsearch request was interrupted for " + path, error);
        } catch (Exception error) {
            throw new ElasticsearchException("Elasticsearch request failed for " + path, error);
        }
    }

    private JsonObject parse(Response response) {
        String body = response.body();
        if (body == null || body.isBlank()) {
            return Json.createObjectBuilder().build();
        }
        try (JsonReader reader = Json.createReader(new StringReader(body))) {
            return reader.readObject();
        } catch (Exception error) {
            throw new ElasticsearchException("Elasticsearch returned a malformed JSON body", error);
        }
    }

    private String baseUri() {
        String value = host == null || host.isBlank() ? "http://localhost:9200" : host.trim();
        while (value.endsWith("/")) {
            value = value.substring(0, value.length() - 1);
        }
        return value;
    }

    private static String normalizePath(String path) {
        if (path == null || path.isBlank()) {
            return "/";
        }
        return path.startsWith("/") ? path : "/" + path;
    }

    private record Response(int status, String body) {
    }
}
