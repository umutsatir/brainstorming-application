package com.brainstorming.controller;

import com.brainstorming.dto.*;
import com.brainstorming.entity.User;
import com.brainstorming.repository.UserRepository;
import com.brainstorming.service.SessionService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teams")
public class TeamController {

    private final UserRepository userRepository;
    private final SessionService sessionService;

    public TeamController(UserRepository userRepository, SessionService sessionService) {
        this.userRepository = userRepository;
        this.sessionService = sessionService;
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @GetMapping
    public ResponseEntity<List<TeamDto>> getAllTeams() {
        // TODO: Implement get all teams
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<TeamDto> getTeamById(@PathVariable Long id) {
        // TODO: Implement get team by id
        return ResponseEntity.ok().build();
    }
    
    @PostMapping
    public ResponseEntity<TeamDto> createTeam(@RequestBody CreateTeamRequest request) {
        // TODO: Implement create team
        return ResponseEntity.ok().build();
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<TeamDto> updateTeam(@PathVariable Long id, @RequestBody CreateTeamRequest request) {
        // TODO: Implement update team
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTeam(@PathVariable Long id) {
        // TODO: Implement delete team
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{id}/members")
    public ResponseEntity<List<TeamMemberDto>> getTeamMembers(@PathVariable Long id) {
        // TODO: Implement get team members
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/{id}/members/{userId}")
    public ResponseEntity<TeamMemberDto> addTeamMember(@PathVariable Long id, @PathVariable Long userId) {
        // TODO: Implement add team member
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{id}/members/{userId}")
    public ResponseEntity<Void> removeTeamMember(@PathVariable Long id, @PathVariable Long userId) {
        // TODO: Implement remove team member
        return ResponseEntity.noContent().build();
    }

    /**
     * 6.1 POST /teams/{teamId}/sessions
     * Create a 6-3-5 session for a team
     * Roles: TEAM_LEADER (own team), EVENT_MANAGER (for any team)
     */
    @PostMapping("/{teamId}/sessions")
    public ResponseEntity<SessionDto> createSessionForTeam(
            @PathVariable Long teamId,
            @Valid @RequestBody CreateSessionRequest request) {
        User currentUser = getCurrentUser();
        SessionDto session = sessionService.createSessionForTeam(
                teamId, 
                request.getTopicId(), 
                request.getRoundCount(), 
                currentUser.getId()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(session);
    }

    /**
     * 6.3 GET /teams/{teamId}/sessions
     * List sessions for one team (with optional status filter)
     */
    @GetMapping("/{teamId}/sessions")
    public ResponseEntity<List<SessionDto>> getTeamSessions(
            @PathVariable Long teamId,
            @RequestParam(required = false) String status) {
        List<SessionDto> sessions = sessionService.getSessionsByTeam(teamId);
        // Filter by status if provided
        if (status != null && !status.isEmpty()) {
            sessions = sessions.stream()
                    .filter(s -> s.getStatus().name().equalsIgnoreCase(status))
                    .toList();
        }
        return ResponseEntity.ok(sessions);
    }
}
