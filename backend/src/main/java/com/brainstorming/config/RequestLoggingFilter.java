package com.brainstorming.config;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.util.ContentCachingRequestWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Component
public class RequestLoggingFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;

        if ("POST".equals(httpRequest.getMethod()) && httpRequest.getRequestURI().contains("/sessions")) {
            ContentCachingRequestWrapper wrappedRequest = new ContentCachingRequestWrapper(httpRequest);

            chain.doFilter(wrappedRequest, response);

            byte[] content = wrappedRequest.getContentAsByteArray();
            if (content.length > 0) {
                String body = new String(content, StandardCharsets.UTF_8);
                System.out.println("========== RAW REQUEST BODY ==========");
                System.out.println(body);
                System.out.println("======================================");
            }
        } else {
            chain.doFilter(request, response);
        }
    }
}
