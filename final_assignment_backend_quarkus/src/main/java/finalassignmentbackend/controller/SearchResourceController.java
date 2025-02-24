package finalassignmentbackend.controller;

import com.manticoresearch.client.model.SearchResponse;
import finalassignmentbackend.service.SearchService;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Response;

@Path("/search")
public class SearchResourceController {

    @Inject
    SearchService searchService;

    @GET
    public Response search(
            @QueryParam("q") String query,
            @QueryParam("index") String indexName) {
        try {
            SearchResponse result = searchService.search(query, indexName);
            return Response.ok(result).build();
        } catch (IllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST).entity(e.getMessage()).build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Search failed: " + e.getMessage())
                    .build();
        }
    }
}