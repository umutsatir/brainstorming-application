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
import com.brainstorming.service.TeamService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teams")
@RequiredArgsConstructor
public class TeamController {

    private final UserRepository userRepository;
    private final SessionService sessionService;
    private final TeamService teamService;

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @GetMapping
    @PreAuthorize("hasRole('EVENT_MANAGER')") // Assuming admin only for listing all
    public ResponseEntity<List<TeamDto>> getAllTeams() {
        return ResponseEntity.ok(teamService.getAllTeams());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER', 'TEAM_MEMBER')")
    public ResponseEntity<TeamDto> getTeamById(@PathVariable Long id) {
        return ResponseEntity.ok(teamService.getTeamById(id));
    }

    @PatchMapping("/{id}")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER')")
    public ResponseEntity<TeamDto> updateTeam(@PathVariable Long id, @RequestBody CreateTeamRequest request) {
        return ResponseEntity.ok(teamService.updateTeam(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER')")
    public ResponseEntity<Void> deleteTeam(@PathVariable Long id) {
        teamService.deleteTeam(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/members")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER', 'TEAM_MEMBER')")
    public ResponseEntity<List<TeamMemberResponseDto>> getTeamMembers(@PathVariable Long id) {
        return ResponseEntity.ok(teamService.getTeamMembers(id));
    }

    @PostMapping("/{id}/members")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER')")
    public ResponseEntity<Void> addTeamMembers(@PathVariable Long id, @RequestBody List<Long> userIds) {
        teamService.addMembers(id, userIds);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}/members/{userId}")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER')")
    public ResponseEntity<Void> removeTeamMember(@PathVariable Long id, @PathVariable Long userId) {
        teamService.removeMember(id, userId);
        return ResponseEntity.noContent().build();
    }

    /**
     * PUT /teams/{teamId}/leader/{userId}
     * Promote a team member to team leader.
     * Only EVENT_MANAGER can perform this action.
     */
    @PutMapping("/{teamId}/leader/{userId}")
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<TeamDto> promoteToLeader(
            @PathVariable Long teamId,
            @PathVariable Long userId) {
        TeamDto updatedTeam = teamService.promoteToLeader(teamId, userId);
        return ResponseEntity.ok(updatedTeam);
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
                currentUser.getId());
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

    @GetMapping("/my-teams")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER', 'TEAM_MEMBER')")
    public ResponseEntity<List<TeamDto>> getMyTeams() {
        User currentUser = getCurrentUser();
        return ResponseEntity.ok(teamService.getTeamsForUser(currentUser.getId()));
    }
}
