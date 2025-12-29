package com.brainstorming.service;

import lombok.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;

@Service
@Slf4j
public class GeminiService {

    private final RestTemplate restTemplate;
    private final String apiKey;
    private final String apiUrl;
    private final String model;

    public GeminiService(
            @Value("${gemini.api-key}") String apiKey,
            @Value("${gemini.api-url:https://generativelanguage.googleapis.com/v1beta/models}") String apiUrl,
            @Value("${gemini.model:gemini-2.5-flash}") String model) {
        this.restTemplate = new RestTemplate();
        this.apiKey = apiKey;
        this.apiUrl = apiUrl;
        this.model = model;
    }

    public List<String> generateSuggestions(String topicTitle, String topicDescription, List<String> existingIdeas,
            String promptOverride) {
        try {
            String prompt = buildSuggestionPrompt(topicTitle, topicDescription, existingIdeas, promptOverride);
            String response = callGemini(prompt);
            return parseSuggestions(response);
        } catch (Exception e) {
            log.error("Error generating AI suggestions", e);
            throw new RuntimeException("Failed to generate AI suggestions: " + e.getMessage(), e);
        }
    }

    public String generateSummary(String topicTitle, String topicDescription, List<String> allIdeas, String style,
            String length, String language) {
        try {
            String prompt = buildSummaryPrompt(topicTitle, topicDescription, allIdeas, style, length, language);
            return callGemini(prompt);
        } catch (Exception e) {
            log.error("Error generating AI summary", e);
            throw new RuntimeException("Failed to generate AI summary: " + e.getMessage(), e);
        }
    }

    private String callGemini(String prompt) {
        if (apiKey == null || apiKey.isEmpty()) {
            throw new RuntimeException("Gemini API key is not configured");
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            // Gemini API URL format:
            // https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}
            String url = String.format("%s/%s:generateContent?key=%s", apiUrl, model, apiKey);

            GeminiRequest request = GeminiRequest.builder()
                    .contents(List.of(
                            GeminiContent.builder()
                                    .parts(List.of(
                                            GeminiPart.builder()
                                                    .text(prompt)
                                                    .build()))
                                    .build()))
                    .build();

            HttpEntity<GeminiRequest> entity = new HttpEntity<>(request, headers);

            ResponseEntity<GeminiResponse> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    entity,
                    GeminiResponse.class);

            if (response.getBody() != null &&
                    response.getBody().getCandidates() != null &&
                    !response.getBody().getCandidates().isEmpty() &&
                    response.getBody().getCandidates().get(0).getContent() != null &&
                    response.getBody().getCandidates().get(0).getContent().getParts() != null &&
                    !response.getBody().getCandidates().get(0).getContent().getParts().isEmpty()) {
                return response.getBody().getCandidates().get(0).getContent().getParts().get(0).getText();
            }

            throw new RuntimeException("Empty response from Gemini");

        } catch (HttpClientErrorException | HttpServerErrorException e) {
            log.error("Gemini API error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("Gemini API error: " + e.getStatusCode(), e);
        } catch (ResourceAccessException e) {
            log.error("Gemini API timeout or connection error", e);
            throw new RuntimeException("Gemini API unavailable", e);
        } catch (Exception e) {
            log.error("Unexpected error calling Gemini", e);
            throw new RuntimeException("Failed to call Gemini API", e);
        }
    }

    private String buildSuggestionPrompt(String topicTitle, String topicDescription, List<String> existingIdeas,
            String promptOverride) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("You are a helpful brainstorming assistant.\n\n");
        prompt.append("Topic: ").append(topicTitle).append("\n");
        if (topicDescription != null && !topicDescription.isEmpty()) {
            prompt.append("Description: ").append(topicDescription).append("\n");
        }

        if (existingIdeas != null && !existingIdeas.isEmpty()) {
            prompt.append("\nExisting ideas from the brainstorming session:\n");
            for (int i = 0; i < existingIdeas.size(); i++) {
                prompt.append(i + 1).append(". ").append(existingIdeas.get(i)).append("\n");
            }
        }

        prompt.append("\nPlease generate 3 creative and innovative ideas related to this topic. ");
        prompt.append("The ideas should be different from the existing ones and build upon them creatively.\n");
        prompt.append("Format your response as a simple list, one idea per line, without numbering.");

        if (promptOverride != null && !promptOverride.isEmpty()) {
            prompt.append("\n\nAdditional instructions: ").append(promptOverride);
        }

        return prompt.toString();
    }

    private String buildSummaryPrompt(String topicTitle, String topicDescription, List<String> allIdeas, String style,
            String length, String language) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("You are a helpful brainstorming assistant.\n\n");
        prompt.append("Topic: ").append(topicTitle).append("\n");
        if (topicDescription != null && !topicDescription.isEmpty()) {
            prompt.append("Description: ").append(topicDescription).append("\n");
        }

        prompt.append("\nAll ideas from the brainstorming session:\n");
        for (int i = 0; i < allIdeas.size(); i++) {
            prompt.append(i + 1).append(". ").append(allIdeas.get(i)).append("\n");
        }

        prompt.append("\nPlease provide a comprehensive summary of these ideas. ");

        if (style != null && !style.isEmpty()) {
            prompt.append("Style: ").append(style).append(". ");
        }
        if (length != null && !length.isEmpty()) {
            prompt.append("Length: ").append(length).append(". ");
        }
        if (language != null && !language.isEmpty()) {
            prompt.append("Language: ").append(language).append(". ");
        }

        prompt.append("\n\nFormat your response as JSON with the following structure:\n");
        prompt.append("{\n");
        prompt.append("  \"summaryText\": \"...\",\n");
        prompt.append("  \"keyThemes\": [\"theme1\", \"theme2\", ...],\n");
        prompt.append("  \"notableIdeas\": [\"idea1\", \"idea2\", ...]\n");
        prompt.append("}");

        return prompt.toString();
    }

    private List<String> parseSuggestions(String response) {
        List<String> suggestions = new ArrayList<>();
        if (response == null || response.isEmpty()) {
            return suggestions;
        }

        String[] lines = response.split("\n");
        for (String line : lines) {
            line = line.trim();
            // Remove numbering if present (e.g., "1. ", "- ", etc.)
            line = line.replaceAll("^\\d+\\.\\s*", "");
            line = line.replaceAll("^-\\s*", "");
            line = line.replaceAll("^\\*\\s*", "");

            if (!line.isEmpty()) {
                suggestions.add(line);
            }
        }

        // Ensure we have exactly 3 suggestions
        while (suggestions.size() < 3 && suggestions.size() < 10) {
            suggestions.add("Additional creative idea");
        }

        return suggestions.subList(0, Math.min(3, suggestions.size()));
    }

    // Gemini API Request/Response DTOs
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    private static class GeminiRequest {
        private List<GeminiContent> contents;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    private static class GeminiContent {
        private List<GeminiPart> parts;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    private static class GeminiPart {
        private String text;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    private static class GeminiResponse {
        private List<GeminiCandidate> candidates;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    private static class GeminiCandidate {
        private GeminiContent content;
    }
}
