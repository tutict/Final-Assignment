package finalassignmentbackend.exception;

/**
 * 业务异常：携带业务错误码，供全局异常处理器转换为对应的 HTTP 响应。
 * 例如乐观锁冲突时抛出 {@code new BusinessException("CONFLICT", "...")}。
 */
public class BusinessException extends RuntimeException {

    private final String code;

    public BusinessException(String message) {
        this("BUSINESS_ERROR", message);
    }

    public BusinessException(String code, String message) {
        super(message);
        this.code = code;
    }

    public BusinessException(String code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
