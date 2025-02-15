package com.tutict.finalassignmentbackend.config.websocket;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface WsAction {

    // 调用的服务
    String service();

    // 调用的服务中的方法
    String action();
}
