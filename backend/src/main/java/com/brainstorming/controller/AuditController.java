package com.brainstorming.controller;

import com.brainstorming.dto.SessionLogDto;
import com.brainstorming.entity.SessionLog;
import com.brainstorming.exception.ResourceNotFoundException;
import com.brainstorming.mapper.SessionLogMapper;
import com.brainstorming.repository.SessionLogRepository;
import com.brainstorming.repository.SessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Audit Controller - Session audit logs
 * Implements FR-602, NFR-400.
 * 
 * Role-based access control:
 * - GET /audit/sessions/{sessionId}/logs: EVENT_MANAGER only
 */
@RestController
@RequestMapping("/api/audit")
@RequiredArgsConstructor
public class AuditController {
    
    private final SessionLogRepository sessionLogRepository;
    private final SessionRepository sessionRepository;
    private final SessionLogMapper sessionLogMapper;
    
    /**
     * GET /audit/sessions/{sessionId}/logs
     * Roles: EVENT_MANAGER
     * Use: View SessionLogs (FR-602, NFR-400)
     * Response: List of events { timestamp, actorId, actionType, payloadSnippet }
     */
    @GetMapping("/sessions/{sessionId}/logs")
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<List<SessionLogDto>> getSessionAuditLogs(@PathVariable Long sessionId) {
        // Verify session exists
        if (!sessionRepository.existsById(sessionId)) {
            throw new ResourceNotFoundException("Session not found with id: " + sessionId);
        }
        
        List<SessionLog> logs = sessionLogRepository.findBySessionIdOrderByCreatedAtDesc(sessionId);
        List<SessionLogDto> logDtos = sessionLogMapper.toDtoList(logs);
        
        return ResponseEntity.ok(logDtos);
    }
}
