package finalassignmentbackend.dto;

import java.util.LinkedHashMap;
import java.util.Map;

public class ApiResponse<T> {
    public boolean success;
    public T data;
    public String message;
    public String errorCode;

    public static <T> ApiResponse<T> ok(T data) {
        ApiResponse<T> response = new ApiResponse<>();
        response.success = true;
        response.data = data;
        return response;
    }

    public static <T> ApiResponse<T> error(String code, String message) {
        ApiResponse<T> response = new ApiResponse<>();
        response.success = false;
        response.errorCode = code;
        response.message = message;
        return response;
    }

    public Map<String, Object> asMap() {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("success", success);
        payload.put("data", data);
        payload.put("message", message);
        payload.put("errorCode", errorCode);
        return payload;
    }
}
