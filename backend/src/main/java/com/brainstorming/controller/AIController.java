package com.brainstorming.controller;

import com.brainstorming.dto.AISuggestionRequest;
import com.brainstorming.dto.AISuggestionResponse;
import com.brainstorming.dto.AISummaryRequest;
import com.brainstorming.dto.AISummaryResponse;
import com.brainstorming.service.AIService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai/sessions")
@RequiredArgsConstructor
public class AIController {

    private final AIService aiService;

    /**
     * 8.1 POST /ai/sessions/{sessionId}/suggestions
     * Request AI ideas given current topic + ideas
     * Roles: TEAM_LEADER, EVENT_MANAGER
     */
    @PostMapping("/{sessionId}/suggestions")
    @PreAuthorize("hasAnyRole('TEAM_LEADER', 'EVENT_MANAGER')")
    public ResponseEntity<AISuggestionResponse> generateSuggestions(
            @PathVariable Long sessionId,
            @RequestBody(required = false) AISuggestionRequest request) {
        
        if (request == null) {
            request = AISuggestionRequest.builder().build();
        }
        
        AISuggestionResponse response = aiService.generateSuggestions(sessionId, request);
        return ResponseEntity.ok(response);
    }

    /**
     * 8.2 POST /ai/sessions/{sessionId}/summary
     * Summarize all ideas of a completed session
     * Roles: EVENT_MANAGER, TEAM_LEADER
     */
    @PostMapping("/{sessionId}/summary")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER')")
    public ResponseEntity<AISummaryResponse> generateSummary(
            @PathVariable Long sessionId,
            @RequestBody(required = false) @Valid AISummaryRequest request) {
        
        if (request == null) {
            request = AISummaryRequest.builder().build();
        }
        
        AISummaryResponse response = aiService.generateSummary(sessionId, request);
        return ResponseEntity.ok(response);
    }
}

