package com.brainstorming.controller;

import com.brainstorming.dto.*;
import com.brainstorming.entity.*;
import com.brainstorming.exception.ResourceNotFoundException;
import com.brainstorming.mapper.IdeaMapper;
import com.brainstorming.mapper.ReportCacheMapper;
import com.brainstorming.mapper.TopicMapper;
import com.brainstorming.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Report Controller - Reporting, Export & Audit
 * Implements FR-300–303, FR-600–602, exportSessionReport scenario, audit requirements.
 * 
 * Role-based access control:
 * - GET /reports/events/{eventId}: EVENT_MANAGER only
 * - GET /reports/sessions/{sessionId}: EVENT_MANAGER, TEAM_LEADER (for own team)
 * - GET /reports/sessions/{sessionId}/export: EVENT_MANAGER only (FR-303, FR-601)
 */
@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {
    
    private final SessionRepository sessionRepository;
    private final RoundRepository roundRepository;
    private final IdeaRepository ideaRepository;
    private final EventRepository eventRepository;
    private final TeamRepository teamRepository;
    private final TopicRepository topicRepository;
    private final EventParticipantRepository participantRepository;
    private final ReportCacheRepository reportCacheRepository;
    private final TeamMemberRepository teamMemberRepository;
    
    private final IdeaMapper ideaMapper;
    private final TopicMapper topicMapper;
    private final ReportCacheMapper reportCacheMapper;
    
    /**
     * GET /reports/sessions/{sessionId}
     * Roles: EVENT_MANAGER, TEAM_LEADER (for own team)
     * Use: Detailed view of a session (FR-301, FR-305, FR-600)
     * Response: session details, ideasByRound, aiSummaries, aiSuggestions, metrics
     */
    @GetMapping("/sessions/{sessionId}")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER')")
    public ResponseEntity<SessionReportDto> getSessionReport(@PathVariable Long sessionId) {
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found with id: " + sessionId));
        
        List<Round> rounds = roundRepository.findBySessionId(sessionId);
        List<Idea> allIdeas = ideaRepository.findBySessionId(sessionId);
        
        // Build round reports
        List<RoundReportDto> roundReports = new ArrayList<>();
        for (Round round : rounds) {
            List<Idea> roundIdeas = allIdeas.stream()
                    .filter(idea -> idea.getRound() != null && idea.getRound().getId().equals(round.getId()))
                    .collect(Collectors.toList());
            
            RoundReportDto roundReport = RoundReportDto.builder()
                    .roundNumber(round.getRoundNumber())
                    .startTime(round.getStartTime())
                    .endTime(round.getEndTime())
                    .timerState(round.getTimerState() != null ? round.getTimerState().name() : null)
                    .ideaCount(roundIdeas.size())
                    .ideas(ideaMapper.toDtoList(roundIdeas))
                    .build();
            
            roundReports.add(roundReport);
        }
        
        SessionReportDto report = SessionReportDto.builder()
                .sessionId(session.getId())
                .topicTitle(session.getTopic() != null ? session.getTopic().getTitle() : null)
                .topicDescription(session.getTopic() != null ? session.getTopic().getDescription() : null)
                .teamName(session.getTeam() != null ? session.getTeam().getName() : null)
                .status(session.getStatus() != null ? session.getStatus().name() : null)
                .currentRound(session.getCurrentRound())
                .roundCount(rounds.size())
                .totalIdeas(allIdeas.size())
                .rounds(roundReports)
                .createdAt(session.getCreatedAt())
                .build();
        
        return ResponseEntity.ok(report);
    }
    
    /**
     * GET /reports/sessions/{sessionId}/export
     * Roles: EVENT_MANAGER (FR-303, FR-601)
     * Query: format=pdf|csv
     * Backend: Call internal export service, stream file to client
     * Response: 200 file download (application/pdf or text/csv)
     */
    @GetMapping("/sessions/{sessionId}/export")
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<Resource> exportSessionReport(
            @PathVariable Long sessionId,
            @RequestParam(defaultValue = "pdf") String format) {
        
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found with id: " + sessionId));
        
        ReportCache.Format reportFormat;
        try {
            reportFormat = ReportCache.Format.valueOf(format.toLowerCase());
        } catch (IllegalArgumentException e) {
            reportFormat = ReportCache.Format.pdf;
        }
        
        // Check if we have a cached report
        ReportCache cachedReport = reportCacheRepository.findBySessionIdAndFormat(sessionId, reportFormat)
                .orElse(null);
        
        if (cachedReport != null && cachedReport.getFilePath() != null) {
            try {
                Path filePath = Paths.get(cachedReport.getFilePath());
                Resource resource = new UrlResource(filePath.toUri());
                
                if (resource.exists()) {
                    String contentType = format.equalsIgnoreCase("csv") 
                            ? "text/csv" 
                            : "application/pdf";
                    
                    return ResponseEntity.ok()
                            .contentType(MediaType.parseMediaType(contentType))
                            .header(HttpHeaders.CONTENT_DISPOSITION, 
                                    "attachment; filename=\"session_" + sessionId + "_report." + format + "\"")
                            .body(resource);
                }
            } catch (Exception e) {
                // If cached file doesn't exist, fall through to generate new report
            }
        }
        
        // TODO: Generate report on-the-fly if no cached version exists
        // For now, return the session report as JSON with appropriate message
        throw new ResourceNotFoundException("No cached report found for session " + sessionId + 
                ". Report generation is not yet implemented.");
    }
    
    /**
     * GET /reports/events/{eventId}
     * Roles: EVENT_MANAGER
     * Use: High-level dashboard: number of sessions, teams, ideas, AI summaries
     * Response: Aggregated stats, list of sessions with statuses
     */
    @GetMapping("/events/{eventId}")
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<EventReportDto> getEventReport(@PathVariable Long eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with id: " + eventId));
        
        List<Team> teams = teamRepository.findByEventId(eventId);
        List<Topic> topics = topicRepository.findByEventId(eventId);
        List<EventParticipant> participants = participantRepository.findByEventId(eventId);
        
        // Count total sessions and ideas
        int totalSessions = 0;
        int totalIdeas = 0;
        
        List<TeamSummaryDto> teamSummaries = new ArrayList<>();
        for (Team team : teams) {
            List<Session> teamSessions = sessionRepository.findByTeamId(team.getId());
            List<Idea> teamIdeas = ideaRepository.findByTeamId(team.getId());
            List<TeamMember> teamMembers = teamMemberRepository.findByTeamId(team.getId());
            
            totalSessions += teamSessions.size();
            totalIdeas += teamIdeas.size();
            
            TeamSummaryDto teamSummary = TeamSummaryDto.builder()
                    .id(team.getId())
                    .name(team.getName())
                    .leaderName(team.getLeader() != null ? team.getLeader().getFullName() : null)
                    .memberCount(teamMembers.size())
                    .sessionCount(teamSessions.size())
                    .totalIdeas(teamIdeas.size())
                    .build();
            
            teamSummaries.add(teamSummary);
        }
        
        EventReportDto report = EventReportDto.builder()
                .eventId(event.getId())
                .eventName(event.getName())
                .eventDescription(event.getDescription())
                .startDate(event.getStartDate())
                .endDate(event.getEndDate())
                .ownerName(event.getOwner() != null ? event.getOwner().getFullName() : null)
                .totalTeams(teams.size())
                .totalTopics(topics.size())
                .totalSessions(totalSessions)
                .totalIdeas(totalIdeas)
                .totalParticipants(participants.size())
                .teams(teamSummaries)
                .topics(topicMapper.toDtoList(topics))
                .build();
        
        return ResponseEntity.ok(report);
    }
}
