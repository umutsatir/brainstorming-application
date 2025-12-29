package com.brainstorming.controller;

import com.brainstorming.dto.*;
import com.brainstorming.entity.Session;
import com.brainstorming.entity.User;
import com.brainstorming.mapper.SessionMapper;
import com.brainstorming.repository.SessionRepository;
import com.brainstorming.repository.UserRepository;
import com.brainstorming.service.SessionService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/sessions")
public class SessionController {

    private final SessionService sessionService;
    private final SessionRepository sessionRepository;
    private final UserRepository userRepository;
    private final SessionMapper sessionMapper;

    public SessionController(SessionService sessionService,
                           SessionRepository sessionRepository,
                           UserRepository userRepository,
                           SessionMapper sessionMapper) {
        this.sessionService = sessionService;
        this.sessionRepository = sessionRepository;
        this.userRepository = userRepository;
        this.sessionMapper = sessionMapper;
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @GetMapping
    public ResponseEntity<List<SessionDto>> getAllSessions() {
        List<Session> sessions = sessionRepository.findAll();
        List<SessionDto> sessionDtos = sessions.stream()
                .map(sessionMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(sessionDtos);
    }
    
    /**
     * 6.2 GET /sessions/{sessionId}
     * View session state: current round, timers, members, etc.
     */
    @GetMapping("/{id}")
    public ResponseEntity<SessionDto> getSessionById(@PathVariable Long id) {
        Session session = sessionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Session not found"));
        return ResponseEntity.ok(sessionMapper.toDto(session));
    }

    /**
     * Get full session state for the 6-3-5 brainstorming page
     * Includes session, current round, timer, ideas, and team submission status
     */
    @GetMapping("/{id}/state")
    public ResponseEntity<SessionStateDto> getSessionState(@PathVariable Long id) {
        User currentUser = getCurrentUser();
        SessionStateDto state = sessionService.getSessionState(id, currentUser.getId());
        return ResponseEntity.ok(state);
    }
    
    @PostMapping
<<<<<<< Updated upstream
    public ResponseEntity<SessionDto> createSession(@RequestBody CreateSessionRequest request) {
        System.out.println("DEBUG CONTROLLER: Received CreateSessionRequest");
        System.out.println("DEBUG CONTROLLER: teamId=" + request.getTeamId());
        System.out.println("DEBUG CONTROLLER: topicId=" + request.getTopicId());
        System.out.println("DEBUG CONTROLLER: roundCount=" + request.getRoundCount());
=======
    public ResponseEntity<SessionDto> createSession(@Valid @RequestBody CreateSessionRequest request) {
>>>>>>> Stashed changes
        SessionDto session = sessionService.createSession(request);
        return ResponseEntity.ok(session);
    }

    /**
     * 6.4 PATCH /sessions/{sessionId}/control
     * Control session - start, pause, resume, or end
     * Roles: TEAM_LEADER (own), EVENT_MANAGER (any)
     */
    @PatchMapping("/{id}/control")
    public ResponseEntity<SessionStateDto> controlSession(
            @PathVariable Long id,
            @Valid @RequestBody SessionControlRequest request) {
        User currentUser = getCurrentUser();
        SessionStateDto state = sessionService.controlSession(id, currentUser.getId(), request.getAction());
        return ResponseEntity.ok(state);
    }

    /**
     * Legacy POST endpoint for control (kept for backward compatibility)
     */
    @PostMapping("/{id}/control")
    public ResponseEntity<SessionStateDto> controlSessionPost(
            @PathVariable Long id,
            @Valid @RequestBody SessionControlRequest request) {
        return controlSession(id, request);
    }
    
    @PostMapping("/{id}/start")
    public ResponseEntity<SessionStateDto> startSession(@PathVariable Long id) {
        User currentUser = getCurrentUser();
        SessionStateDto state = sessionService.startSession(id, currentUser.getId());
        return ResponseEntity.ok(state);
    }
    
    @PostMapping("/{id}/pause")
    public ResponseEntity<SessionStateDto> pauseSession(@PathVariable Long id) {
        User currentUser = getCurrentUser();
        SessionStateDto state = sessionService.pauseSession(id, currentUser.getId());
        return ResponseEntity.ok(state);
    }

    @PostMapping("/{id}/resume")
    public ResponseEntity<SessionStateDto> resumeSession(@PathVariable Long id) {
        User currentUser = getCurrentUser();
        SessionStateDto state = sessionService.resumeSession(id, currentUser.getId());
        return ResponseEntity.ok(state);
    }
    
    @PostMapping("/{id}/complete")
    public ResponseEntity<SessionStateDto> completeSession(@PathVariable Long id) {
        User currentUser = getCurrentUser();
        SessionStateDto state = sessionService.completeSession(id, currentUser.getId());
        return ResponseEntity.ok(state);
    }

    /**
     * 6.5 POST /sessions/{sessionId}/rounds/{roundNumber}/advance
     * Advance to next round with idea passing
     * Roles: SYSTEM (timer), TEAM_LEADER, EVENT_MANAGER
     */
    @PostMapping("/{id}/rounds/{roundNumber}/advance")
    public ResponseEntity<AdvanceRoundResponseDto> advanceRound(
            @PathVariable Long id,
            @PathVariable Integer roundNumber) {
        User currentUser = getCurrentUser();
        AdvanceRoundResponseDto response = sessionService.advanceRoundWithPassing(id, currentUser.getId());
        return ResponseEntity.ok(response);
    }

    /**
     * 6.6 GET /sessions/{sessionId}/rounds
     * List all rounds and their status
     */
    @GetMapping("/{id}/rounds")
    public ResponseEntity<List<RoundDto>> getSessionRounds(@PathVariable Long id) {
        List<RoundDto> rounds = sessionService.getSessionRounds(id);
        return ResponseEntity.ok(rounds);
    }

    /**
     * 6.7 GET /sessions/{sessionId}/rounds/{roundNumber}
     * Detail of a single round: timer state, members that have submitted
     */
    @GetMapping("/{id}/rounds/{roundNumber}")
    public ResponseEntity<RoundDetailDto> getRoundDetail(
            @PathVariable Long id,
            @PathVariable Integer roundNumber) {
        User currentUser = getCurrentUser();
        RoundDetailDto roundDetail = sessionService.getRoundDetail(id, roundNumber, currentUser.getId());
        return ResponseEntity.ok(roundDetail);
    }
    
    /**
     * 7.4 GET /sessions/{sessionId}/ideas
     * View aggregated ideas across all rounds (grouped by round & participant)
     * Roles: TEAM_LEADER (own team), EVENT_MANAGER
     */
    @GetMapping("/{id}/ideas")
    public ResponseEntity<SessionIdeasResponseDto> getSessionIdeas(@PathVariable Long id) {
        User currentUser = getCurrentUser();
        SessionIdeasResponseDto response = sessionService.getSessionIdeasGrouped(id, currentUser.getId());
        return ResponseEntity.ok(response);
    }
}
