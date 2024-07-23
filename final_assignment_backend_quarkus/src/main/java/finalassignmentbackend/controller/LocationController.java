package finalassignmentbackend.controller;


import finalassignmentbackend.utils.GaoDeGeocoder;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import java.util.Map;

@Path("/eventbus/")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class LocationController {

    @Inject
    GaoDeGeocoder gaoDeGeocoder;

//    @PostMapping("/location")
    @POST
    @Path("/location")
    public String handleLocation(Map<String, Object> locationData) throws Exception {

        double longitude = (double) locationData.get("laitude");
        double latitude = (double) locationData.get("longitude");

        String address = gaoDeGeocoder.getAddress(longitude, latitude);

        return "你的地址是" + address;
    }
}
