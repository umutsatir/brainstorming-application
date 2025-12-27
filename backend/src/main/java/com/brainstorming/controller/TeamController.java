package com.brainstorming.controller;

import com.brainstorming.dto.*;
import com.brainstorming.service.TeamService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teams")
@RequiredArgsConstructor
public class TeamController {

    private final TeamService teamService;
    
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
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<Void> deleteTeam(@PathVariable Long id) {
        teamService.deleteTeam(id);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{id}/members")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER', 'TEAM_MEMBER')")
    public ResponseEntity<List<UserDto>> getTeamMembers(@PathVariable Long id) {
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
}
