package finalassignmentbackend.utils;

import com.alibaba.fastjson2.JSONObject;
import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.apache.hc.core5.http.HttpEntity;
import org.springframework.stereotype.Component;

@Component
public class GaoDeGeocoder {

    private static final String GAODE_GEOCODE_URL = "https://restapi.amap.com/v3/geocode/regeo";
    private static final String API_KEY = "YOUR_GAODE_API_KEY";

    /**
     * 调用高德地图API
     * @param Latitude
     * @param Longitude
     * @return
     * @throws Exception
     */
    public String getAddress(double Latitude, double Longitude) throws Exception {
        String url = GAODE_GEOCODE_URL + "?location=" + Longitude + "," + Latitude + "&key=" + API_KEY;

        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpGet httpGet = new HttpGet(url);
        CloseableHttpResponse response = httpClient.execute(httpGet);

        try {
            HttpEntity entity = response.getEntity();
            String responseBody = EntityUtils.toString(entity, "UTF-8");
            JSONObject jsonObject = JSONObject.parseObject(responseBody);

            if (jsonObject.getIntValue("infocode") == 10000) {
                JSONObject regeocode = jsonObject.getJSONObject("regeocode");
                JSONObject addressComponent = regeocode.getJSONObject("addressComponent");
                return addressComponent.getString("formattedAddress");
            } else {
                return "geocode error: " + jsonObject.getString("info");
            }
        } finally {
            response.close();
            httpClient.close();
        }
    }
}
