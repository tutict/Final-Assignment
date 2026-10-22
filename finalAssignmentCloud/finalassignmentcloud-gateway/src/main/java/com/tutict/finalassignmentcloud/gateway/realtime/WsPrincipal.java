package com.tutict.finalassignmentcloud.gateway.realtime;

import java.security.Principal;
import java.util.List;

/**
 * WebSocket 握手通过后写入 Principal 的调用方身份。
 */
public final class WsPrincipal implements Principal {

    private final String name;
    private final List<String> roles;

    public WsPrincipal(String name, List<String> roles) {
        this.name = name;
        this.roles = roles == null ? List.of() : List.copyOf(roles);
    }

    @Override
    public String getName() {
        return name;
    }

    public List<String> getRoles() {
        return roles;
    }
}
