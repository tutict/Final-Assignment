package com.tutict.finalassignmentcloud.ai.agent;

import java.util.Map;

public final class AgentArgs {

    private AgentArgs() {
    }

    public static String str(Map<String, Object> args, String... keys) {
        Object value = first(args, keys);
        return value == null ? null : value.toString().trim();
    }

    public static Long lng(Map<String, Object> args, String... keys) {
        Object value = first(args, keys);
        if (value == null || value.toString().isBlank()) {
            return null;
        }
        if (value instanceof Number number) {
            return number.longValue();
        }
        try {
            return Long.parseLong(value.toString().trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    public static Integer integer(Map<String, Object> args, String... keys) {
        Long value = lng(args, keys);
        return value == null ? null : value.intValue();
    }

    public static int page(Map<String, Object> args) {
        Integer value = integer(args, "page");
        return value == null || value < 0 ? 0 : value;
    }

    public static int size(Map<String, Object> args, int fallback) {
        Integer value = integer(args, "size", "limit");
        if (value == null || value <= 0) {
            return fallback;
        }
        return Math.min(value, 50);
    }

    public static boolean bool(Map<String, Object> args, String key) {
        Object value = first(args, key);
        if (value instanceof Boolean flag) {
            return flag;
        }
        return value != null && Boolean.parseBoolean(value.toString());
    }

    public static Object first(Map<String, Object> args, String... keys) {
        if (args == null || keys == null) {
            return null;
        }
        for (String key : keys) {
            if (args.containsKey(key) && args.get(key) != null) {
                return args.get(key);
            }
        }
        return null;
    }
}
