package finalassignmentbackend.service;

import com.manticoresearch.client.api.SearchApi;
import com.manticoresearch.client.model.SearchQuery;
import com.manticoresearch.client.model.SearchRequest;
import com.manticoresearch.client.model.SearchResponse;
import finalassignmentbackend.config.ManticoreClientConfig;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.util.Set;

@ApplicationScoped
public class SearchService {

    @Inject
    ManticoreClientConfig manticoreClientConfig;

    private static final Set<String> ALLOWED_INDEXES = Set.of("offense_index", "driver_index");

    public SearchResponse search(String query, String indexName) throws Exception {
        if (query == null || query.trim().isEmpty()) {
            throw new IllegalArgumentException("Query string cannot be null or empty");
        }
        if (indexName == null || indexName.trim().isEmpty()) {
            throw new IllegalArgumentException("Index name cannot be null or empty");
        }
        if (!ALLOWED_INDEXES.contains(indexName.trim())) {
            throw new IllegalArgumentException("Invalid index name: " + indexName);
        }

        SearchApi searchApi = manticoreClientConfig.getSearchApi();
        SearchRequest request = new SearchRequest();
        request.setTable(indexName.trim());

        SearchQuery searchQuery = new SearchQuery();
        searchQuery.setQueryString(query.trim());
        request.setQuery(searchQuery);

        return searchApi.search(request);
    }
}