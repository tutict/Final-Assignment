package finalassignmentbackend.config;

import com.manticoresearch.client.ApiClient;
import com.manticoresearch.client.Configuration;
import com.manticoresearch.client.api.SearchApi;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class ManticoreClientConfig {

    @ConfigProperty(name = "manticore.host", defaultValue = "http://localhost:9308")
    String manticoreHost;

    // 获取默认的 ApiClient
    public ApiClient getManticoreClient() {
        ApiClient client = Configuration.getDefaultApiClient();
        client.setBasePath(manticoreHost);
        return client;
    }

    // 获取 SearchApi 实例
    public SearchApi getSearchApi() {
        return new SearchApi(getManticoreClient());
    }
}