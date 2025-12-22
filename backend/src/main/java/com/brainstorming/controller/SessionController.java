package com.brainstorming.controller;

import com.brainstorming.dto.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sessions")
public class SessionController {

    // TODO: Inject SessionService
    
    @GetMapping
    public ResponseEntity<List<SessionDto>> getAllSessions() {
        // TODO: Implement get all sessions
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<SessionDto> getSessionById(@PathVariable Long id) {
        // TODO: Implement get session by id
        return ResponseEntity.ok().build();
    }
    
    @PostMapping
    public ResponseEntity<SessionDto> createSession(@RequestBody CreateSessionRequest request) {
        // TODO: Implement create session
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/{id}/start")
    public ResponseEntity<SessionDto> startSession(@PathVariable Long id) {
        // TODO: Implement start session
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/{id}/pause")
    public ResponseEntity<SessionDto> pauseSession(@PathVariable Long id) {
        // TODO: Implement pause session
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/{id}/complete")
    public ResponseEntity<SessionDto> completeSession(@PathVariable Long id) {
        // TODO: Implement complete session
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{id}/rounds")
    public ResponseEntity<List<RoundDto>> getSessionRounds(@PathVariable Long id) {
        // TODO: Implement get session rounds
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{id}/ideas")
    public ResponseEntity<List<IdeaDto>> getSessionIdeas(@PathVariable Long id) {
        // TODO: Implement get session ideas
        return ResponseEntity.ok().build();
    }
}
