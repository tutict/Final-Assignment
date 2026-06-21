package com.tutict.finalassignmentbackend.config.websocket;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface WsAction {

    // WebSocket service name.
    String service();

    // WebSocket action name within the service.
    String action();

    // Required role codes. Empty means deny unless allowAuthenticated is true.
    String[] roles() default {};

    // Use only for legacy actions that need a valid token but no specific role.
    boolean allowAuthenticated() default false;
}