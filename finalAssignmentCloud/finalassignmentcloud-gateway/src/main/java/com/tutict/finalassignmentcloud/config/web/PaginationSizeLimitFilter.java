package com.tutict.finalassignmentcloud.config.web;

import com.tutict.finalassignmentcloud.common.PageLimits;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 20)
public class PaginationSizeLimitFilter extends OncePerRequestFilter {

    private final int maxPageSize;

    public PaginationSizeLimitFilter(@Value("${app.pagination.max-size:100}") int maxPageSize) {
        this.maxPageSize = PageLimits.normalizeLimit(maxPageSize, PageLimits.MAX_PAGE_SIZE);
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String size = request.getParameter("size");
        if (size != null && isReadRequest(request)) {
            Integer parsedSize = parseSize(size);
            if (parsedSize == null || parsedSize > maxPageSize) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                response.getWriter().write("""
                        {"success":false,"errorCode":"PAGE_SIZE_LIMIT_EXCEEDED","message":"page size exceeds server limit"}
                        """);
                return;
            }
        }
        filterChain.doFilter(request, response);
    }

    private boolean isReadRequest(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod());
    }

    private Integer parseSize(String size) {
        try {
            return Integer.parseInt(size);
        } catch (NumberFormatException ex) {
            return null;
        }
    }
}
