package com.tutict.finalassignmentbackend.config.ai;

import java.util.List;
import java.util.Map;

public interface BaiduSearch {
    List<Map<String, String>> search(String query);
}