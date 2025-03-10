package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.ai.BaiduSearch;
import com.tutict.finalassignmentbackend.config.ai.GraalPyContext;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

//@Service
public class AIChatSearchService {
    private final BaiduSearch baiduSearch;

    public AIChatSearchService(GraalPyContext context) {
        var value = context.eval("""
                from baidusearch.baidusearch import search
                results = search('China', num_results=20)
                """);
        baiduSearch = value.as(BaiduSearch.class);
    }

    public List<Map<String, String>> search(String query) {
        return baiduSearch.search(query);
    }
}