package com.brainstorming.controller;

import com.brainstorming.dto.*;
import com.brainstorming.entity.Idea;
import com.brainstorming.entity.User;
import com.brainstorming.mapper.IdeaMapper;
import com.brainstorming.repository.IdeaRepository;
import com.brainstorming.repository.UserRepository;
import com.brainstorming.service.IdeaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public class IdeaController {

    private final IdeaService ideaService;
    private final IdeaRepository ideaRepository;
    private final UserRepository userRepository;
    private final IdeaMapper ideaMapper;

    public IdeaController(IdeaService ideaService,
                         IdeaRepository ideaRepository,
                         UserRepository userRepository,
                         IdeaMapper ideaMapper) {
        this.ideaService = ideaService;
        this.ideaRepository = ideaRepository;
        this.userRepository = userRepository;
        this.ideaMapper = ideaMapper;
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @GetMapping("/ideas")
    public ResponseEntity<List<IdeaDto>> getAllIdeas() {
        List<Idea> ideas = ideaRepository.findAll();
        List<IdeaDto> ideaDtos = ideas.stream()
                .map(ideaMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ideaDtos);
    }
    
    @GetMapping("/ideas/{id}")
    public ResponseEntity<IdeaDto> getIdeaById(@PathVariable Long id) {
        Idea idea = ideaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Idea not found"));
        return ResponseEntity.ok(ideaMapper.toDto(idea));
    }

    /**
     * 7.2 POST /sessions/{sessionId}/rounds/{roundNumber}/ideas
     * Submit 3 ideas for current round (FR-201, FR-202, FR-306)
     * Roles: TEAM_MEMBER (and Team Leader if also a member)
     */
    @PostMapping("/sessions/{sessionId}/rounds/{roundNumber}/ideas")
    public ResponseEntity<SubmitIdeasResponse> submitIdeas(
            @PathVariable Long sessionId,
            @PathVariable Integer roundNumber,
            @Valid @RequestBody SubmitIdeasRequest request) {
        User currentUser = getCurrentUser();
        SubmitIdeasResponse response = ideaService.submitIdeas(
                sessionId, roundNumber, currentUser.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * 7.1 GET /sessions/{sessionId}/rounds/{roundNumber}/ideas
     * Get ideas for a round with submission status
     * Shows previous teammate ideas, own ideas, and submission counts
     * Roles: TEAM_MEMBER & TEAM_LEADER in that team, EVENT_MANAGER
     */
    @GetMapping("/sessions/{sessionId}/rounds/{roundNumber}/ideas")
    public ResponseEntity<RoundIdeasResponseDto> getRoundIdeasForUser(
            @PathVariable Long sessionId,
            @PathVariable Integer roundNumber) {
        User currentUser = getCurrentUser();
        RoundIdeasResponseDto response = ideaService.getRoundIdeasForUser(
                sessionId, roundNumber, currentUser.getId());
        return ResponseEntity.ok(response);
    }

    /**
     * Get ideas passed from the previous participant in the team rotation
     * For round N, returns ideas from user (current-1) from round (N-1)
     */
    @GetMapping("/sessions/{sessionId}/rounds/{roundNumber}/previous-ideas")
    public ResponseEntity<List<IdeaDto>> getPreviousIdeas(
            @PathVariable Long sessionId,
            @PathVariable Integer roundNumber) {
        User currentUser = getCurrentUser();
        List<IdeaDto> ideas = ideaService.getPreviousRoundIdeas(
                sessionId, roundNumber, currentUser.getId());
        return ResponseEntity.ok(ideas);
    }
    
    @PostMapping("/ideas")
    public ResponseEntity<IdeaDto> createIdea(@RequestBody CreateIdeaRequest request) {
        User currentUser = getCurrentUser();
        IdeaDto idea = ideaService.createIdea(request, currentUser.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(idea);
    }
    
    /**
     * 7.3 PATCH /ideas/{ideaId}
     * Update an idea (edit text)
     * Roles: TEAM_MEMBER (own idea) before round lock, TEAM_LEADER/EM for moderation
     */
    @PatchMapping("/ideas/{id}")
    public ResponseEntity<IdeaDto> updateIdea(
            @PathVariable Long id, 
            @Valid @RequestBody UpdateIdeaRequest request) {
        User currentUser = getCurrentUser();
        IdeaDto idea = ideaService.updateIdea(id, request, currentUser.getId());
        return ResponseEntity.ok(idea);
    }

    /**
     * Legacy PUT endpoint for update (kept for backward compatibility)
     */
    @PutMapping("/ideas/{id}")
    public ResponseEntity<IdeaDto> updateIdeaPut(
            @PathVariable Long id, 
            @RequestBody UpdateIdeaRequest request) {
        return updateIdea(id, request);
    }
    
    @DeleteMapping("/ideas/{id}")
    public ResponseEntity<Void> deleteIdea(@PathVariable Long id) {
        User currentUser = getCurrentUser();
        ideaService.deleteIdea(id, currentUser.getId());
        return ResponseEntity.noContent().build();
    }
}
