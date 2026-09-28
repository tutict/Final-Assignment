package com.tutict.finalassignmentcloud.exception;

public class DependencyUnavailableException extends RuntimeException {

    public DependencyUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }

    public static boolean unavailable(int status) {
        return status == 503 || status == 504 || status < 0;
    }
}