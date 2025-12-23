package com.brainstorming.controller;

import com.brainstorming.dto.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teams")
public class TeamController {

    // TODO: Inject TeamService
    
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
}
