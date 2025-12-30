package com.brainstorming.service;

import com.brainstorming.dto.AISuggestionRequest;
import com.brainstorming.dto.AISuggestionResponse;
import com.brainstorming.dto.AISummaryRequest;
import com.brainstorming.dto.AISummaryResponse;
import com.brainstorming.entity.AiArtifact;
import com.brainstorming.entity.Idea;
import com.brainstorming.entity.Round;
import com.brainstorming.entity.Session;
import com.brainstorming.exception.BadRequestException;
import com.brainstorming.exception.ResourceNotFoundException;
import com.brainstorming.repository.AiArtifactRepository;
import com.brainstorming.repository.IdeaRepository;
import com.brainstorming.repository.RoundRepository;
import com.brainstorming.repository.SessionRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AIService {

    private final SessionRepository sessionRepository;
    private final IdeaRepository ideaRepository;
    private final RoundRepository roundRepository;
    private final AiArtifactRepository aiArtifactRepository;
    private final GeminiService geminiService;
    private final ObjectMapper objectMapper;

    @Transactional
    public AISuggestionResponse generateSuggestions(Long sessionId, AISuggestionRequest request) {
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found with id: " + sessionId));

        // Fetch ideas up to specified round (or all if roundNumber is null)
        List<Idea> ideas;
        Round round = null;

        if (request.getRoundNumber() != null) {
            round = roundRepository.findBySessionIdAndRoundNumber(sessionId, request.getRoundNumber())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Round " + request.getRoundNumber() + " not found for session " + sessionId));
            ideas = ideaRepository.findBySessionIdAndRoundId(sessionId, round.getId());
        } else {
            // Get ideas from all rounds up to current round
            ideas = ideaRepository.findBySessionId(sessionId);
        }

        // Extract idea texts
        List<String> ideaTexts = ideas.stream()
                .map(Idea::getText)
                .collect(Collectors.toList());

        try {
            // Call Gemini service
            List<String> suggestions = geminiService.generateSuggestions(
                    session.getTopic().getTitle(),
                    session.getTopic().getDescription(),
                    ideaTexts,
                    request.getPromptOverride());

            // Save AI artifact
            AiArtifact artifact = AiArtifact.builder()
                    .session(session)
                    .round(round)
                    .type(AiArtifact.Type.SUGGESTION)
                    .content(buildSuggestionContent(suggestions))
                    .build();

            AiArtifact savedArtifact = aiArtifactRepository.save(artifact);

            // Build response
            List<AISuggestionResponse.Suggestion> suggestionList = suggestions.stream()
                    .map(text -> AISuggestionResponse.Suggestion.builder()
                            .id(savedArtifact.getId())
                            .text(text)
                            .build())
                    .collect(Collectors.toList());

            return AISuggestionResponse.builder()
                    .suggestions(suggestionList)
                    .build();

        } catch (RuntimeException e) {
            log.error("Error generating AI suggestions for session {}", sessionId, e);
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "AI service unavailable: " + e.getMessage(),
                    e);
        }
    }

    @Transactional
    public AISummaryResponse generateSummary(Long sessionId, AISummaryRequest request) {
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found with id: " + sessionId));

        // Validate session is COMPLETED
        if (session.getStatus() != Session.Status.COMPLETED) {
            throw new BadRequestException(
                    "Session must be COMPLETED to generate summary. Current status: " + session.getStatus());
        }

        // Fetch all ideas from the session
        List<Idea> ideas = ideaRepository.findBySessionId(sessionId);
        List<String> ideaTexts = ideas.stream()
                .map(Idea::getText)
                .collect(Collectors.toList());

        if (ideaTexts.isEmpty()) {
            throw new BadRequestException("Cannot generate summary: No ideas found in this session. Please add ideas before generating a summary.");
        }

        try {
            // Call Gemini service
            String rawSummaryJson = geminiService.generateSummary(
                    session.getTopic().getTitle(),
                    session.getTopic().getDescription(),
                    ideaTexts,
                    request.getStyle(),
                    request.getLength(),
                    request.getLanguage());

            // Clean JSON string
            String summaryJson = cleanJsonString(rawSummaryJson);

            // Parse JSON response
            Map<String, Object> summaryData = parseSummaryResponse(summaryJson);

            // Save AI artifact
            AiArtifact artifact = AiArtifact.builder()
                    .session(session)
                    .round(null) // Summary is for entire session
                    .type(AiArtifact.Type.SUMMARY)
                    .content(summaryJson)
                    .build();

            AiArtifact savedArtifact = aiArtifactRepository.save(artifact);

            // Build response
            @SuppressWarnings("unchecked")
            List<String> keyThemes = (List<String>) summaryData.getOrDefault("keyThemes", List.of());
            @SuppressWarnings("unchecked")
            List<String> notableIdeas = (List<String>) summaryData.getOrDefault("notableIdeas", List.of());

            return AISummaryResponse.builder()
                    .summaryId(savedArtifact.getId())
                    .summaryText((String) summaryData.getOrDefault("summaryText", ""))
                    .keyThemes(keyThemes)
                    .notableIdeas(notableIdeas)
                    .build();

        } catch (RuntimeException e) {
            log.error("Error generating AI summary for session {}", sessionId, e);
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "AI service unavailable: " + e.getMessage(),
                    e);
        }
    }

    public AISummaryResponse getLatestSummary(Long sessionId) {
        List<AiArtifact> artifacts = aiArtifactRepository.findBySessionIdAndType(sessionId, AiArtifact.Type.SUMMARY);
        
        if (artifacts.isEmpty()) {
            return null;
        }
        
        // Get the most recent one (assuming ID is increasing)
        AiArtifact latestArtifact = artifacts.get(artifacts.size() - 1);
        
        Map<String, Object> summaryData = parseSummaryResponse(latestArtifact.getContent());
        
        @SuppressWarnings("unchecked")
        List<String> keyThemes = (List<String>) summaryData.getOrDefault("keyThemes", List.of());
        @SuppressWarnings("unchecked")
        List<String> notableIdeas = (List<String>) summaryData.getOrDefault("notableIdeas", List.of());

        return AISummaryResponse.builder()
                .summaryId(latestArtifact.getId())
                .summaryText((String) summaryData.getOrDefault("summaryText", ""))
                .keyThemes(keyThemes)
                .notableIdeas(notableIdeas)
                .build();
    }

    private String buildSuggestionContent(List<String> suggestions) {
        try {
            Map<String, Object> content = new HashMap<>();
            content.put("suggestions", suggestions);
            return objectMapper.writeValueAsString(content);
        } catch (Exception e) {
            log.error("Error building suggestion content", e);
            return "{\"suggestions\": " + suggestions + "}";
        }
    }

    private String cleanJsonString(String jsonResponse) {
        if (jsonResponse == null) return "{}";
        String cleanJson = jsonResponse.trim();
        if (cleanJson.startsWith("```json")) {
            cleanJson = cleanJson.substring(7);
        } else if (cleanJson.startsWith("```")) {
            cleanJson = cleanJson.substring(3);
        }
        if (cleanJson.endsWith("```")) {
            cleanJson = cleanJson.substring(0, cleanJson.length() - 3);
        }
        return cleanJson.trim();
    }

    private Map<String, Object> parseSummaryResponse(String jsonResponse) {
        try {
            // Try to parse as JSON first
            return objectMapper.readValue(jsonResponse, new TypeReference<Map<String, Object>>() {
            });
        } catch (Exception e) {
            log.warn("Failed to parse summary as JSON, treating as plain text", e);
            // If parsing fails, create a simple structure
            Map<String, Object> result = new HashMap<>();
            result.put("summaryText", jsonResponse);
            result.put("keyThemes", List.of());
            result.put("notableIdeas", List.of());
            return result;
        }
    }
}
