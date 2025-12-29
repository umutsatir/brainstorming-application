package com.brainstorming.websocket;

import com.brainstorming.dto.*;
import com.brainstorming.service.JwtService;
import com.brainstorming.service.SessionService;
import com.brainstorming.service.IdeaService;
import com.brainstorming.repository.UserRepository;
import com.brainstorming.repository.TeamMemberRepository;
import com.brainstorming.repository.IdeaRepository;
import com.brainstorming.repository.RoundRepository;
import com.brainstorming.repository.SessionRepository;
import com.brainstorming.entity.User;
import com.brainstorming.entity.Session;
import com.brainstorming.entity.Round;
import com.brainstorming.entity.TeamMember;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.net.URI;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CompletableFuture;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
@RequiredArgsConstructor
@Slf4j
public class SessionWebSocketHandler extends TextWebSocketHandler {

    private final SessionService sessionService;
    private final IdeaService ideaService;
    private final JwtService jwtService;
    private final UserRepository userRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final IdeaRepository ideaRepository;
    private final RoundRepository roundRepository;
    private final SessionRepository sessionRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final ObjectMapper objectMapper;

    // Map of sessionId to Map of WebSocket sessions
    private final Map<Long, Map<String, WebSocketSession>> sessionConnections = new ConcurrentHashMap<>();
    // Map of WebSocket session to user info
    private final Map<String, UserSessionInfo> sessionUserInfo = new ConcurrentHashMap<>();

    private static final Pattern SESSION_ID_PATTERN = Pattern.compile("/ws/sessions/(\\d+)");

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        log.info("WebSocket connection established: {}", session.getId());
        
        // Extract session ID from URI
        Long sessionId = extractSessionId(session.getUri());
        if (sessionId == null) {
            session.close(CloseStatus.BAD_DATA.withReason("Invalid session ID"));
            return;
        }

        // Extract token from query params and validate
        String token = extractToken(session.getUri());
        if (token == null || isTokenInvalid(token)) {
            session.close(CloseStatus.NOT_ACCEPTABLE.withReason("Invalid or missing token"));
            return;
        }

        // Get user from token (using email from JWT subject)
        String email = jwtService.extractEmail(token);
        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            session.close(CloseStatus.NOT_ACCEPTABLE.withReason("User not found"));
            return;
        }

        // Store connection info
        UserSessionInfo userInfo = new UserSessionInfo(user.getId(), user.getEmail(), user.getFullName(), sessionId);
        sessionUserInfo.put(session.getId(), userInfo);

        // Add to session connections
        sessionConnections.computeIfAbsent(sessionId, k -> new ConcurrentHashMap<>())
                .put(session.getId(), session);

        log.info("User {} joined session {}", user.getEmail(), sessionId);

        // Send current session state to the connected user
        try {
            SessionStateDto state = sessionService.getSessionState(sessionId, user.getId());
            sendMessage(session, new WebSocketMessage("session_state", state));
        } catch (Exception e) {
            log.error("Failed to send initial session state", e);
        }

        // Notify other participants about the new connection
        broadcastToSession(sessionId, new WebSocketMessage("user_joined", Map.of(
                "userId", user.getId(),
                "userName", user.getFullName()
        )), session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        UserSessionInfo userInfo = sessionUserInfo.get(session.getId());
        if (userInfo == null) {
            return;
        }

        try {
            WebSocketMessage wsMessage = objectMapper.readValue(message.getPayload(), WebSocketMessage.class);
            handleWebSocketMessage(session, wsMessage, userInfo);
        } catch (Exception e) {
            log.error("Failed to handle WebSocket message", e);
            sendMessage(session, new WebSocketMessage("error", Map.of("message", "Invalid message format")));
        }
    }

    private void handleWebSocketMessage(WebSocketSession session, WebSocketMessage message, UserSessionInfo userInfo) throws Exception {
        Long sessionId = userInfo.getSessionId();
        Long userId = userInfo.getUserId();

        switch (message.getType()) {
            case "submit_ideas" -> handleSubmitIdeas(session, message, sessionId, userId);
            case "session_control" -> handleSessionControl(session, message, sessionId, userId);
            case "ping" -> sendMessage(session, new WebSocketMessage("pong", null));
            default -> log.warn("Unknown message type: {}", message.getType());
        }
    }

    @SuppressWarnings("unchecked")
    private void handleSubmitIdeas(WebSocketSession session, WebSocketMessage message, Long sessionId, Long userId) throws Exception {
        Map<String, Object> data = (Map<String, Object>) message.getPayload();
        Integer roundNumber = (Integer) data.get("roundNumber");
        List<String> ideas = (List<String>) data.get("ideas");

        try {
            SubmitIdeasRequest request = new SubmitIdeasRequest();
            request.setIdeas(ideas);
            SubmitIdeasResponse response = ideaService.submitIdeas(sessionId, roundNumber, userId, request);

            // Send confirmation to submitter
            sendMessage(session, new WebSocketMessage("ideas_submitted", response));

            // Get user info for broadcasting
            UserSessionInfo userInfo = sessionUserInfo.get(session.getId());

            // Broadcast member_submitted event to ALL users (including sender)
            broadcastToSession(sessionId, new WebSocketMessage("ideas_submitted", Map.of(
                    "user_id", userId,
                    "user_name", userInfo.getFullName(),
                    "round_number", roundNumber
            )), null);  // null = broadcast to everyone including sender

            // Broadcast updated session state to all participants
            broadcastSessionState(sessionId);

            // Check if all team members have submitted and auto-advance if so (async to avoid blocking)
            CompletableFuture.runAsync(() -> checkAndAdvanceRound(sessionId, roundNumber));
        } catch (Exception e) {
            log.error("Failed to submit ideas", e);
            sendMessage(session, new WebSocketMessage("error", Map.of("message", e.getMessage())));
        }
    }

    private void checkAndAdvanceRound(Long sessionId, Integer roundNumber) {
        try {
            Session sess = sessionRepository.findById(sessionId).orElse(null);
            if (sess == null || sess.getStatus() != Session.Status.RUNNING) {
                return;
            }

            Round currentRound = roundRepository.findBySessionIdAndRoundNumber(sessionId, roundNumber).orElse(null);
            if (currentRound == null || currentRound.getTimerState() == Round.TimerState.FINISHED) {
                return;
            }

            // Get total number of team members
            List<TeamMember> teamMembers = teamMemberRepository.findByTeamId(sess.getTeam().getId());
            long totalMembers = teamMembers.size();

            // Get number of members who have submitted for this round
            long submittedCount = ideaRepository.findBySessionIdAndRoundId(sessionId, currentRound.getId())
                    .stream()
                    .map(idea -> idea.getAuthor().getId())
                    .distinct()
                    .count();

            log.info("Round {} - {}/{} members have submitted", roundNumber, submittedCount, totalMembers);

            // If all members have submitted, trigger round advance immediately
            if (submittedCount >= totalMembers && totalMembers > 0) {
                log.info("All members submitted for round {}, auto-advancing to next round", roundNumber);

                // Mark timer as finished
                currentRound.setTimerState(Round.TimerState.FINISHED);
                currentRound.setEndTime(LocalDateTime.now());
                roundRepository.save(currentRound);

                // Check if this was the last round
                if (currentRound.getRoundNumber() >= sess.getRoundCount()) {
                    // Session is complete
                    sess.setStatus(Session.Status.COMPLETED);
                    sessionRepository.save(sess);

                    broadcastToSession(sessionId, new WebSocketMessage("session_completed", Map.of(
                            "sessionId", sessionId,
                            "message", "Brainstorming session completed!"
                    )), null);
                } else {
                    // Start next round
                    startNextRound(sess, currentRound.getRoundNumber() + 1);
                }

                // Signal all clients to refresh their state
                broadcastToSession(sessionId, new WebSocketMessage("refresh_state", Map.of(
                        "message", "All members submitted, round advanced"
                )), null);
            }
        } catch (Exception e) {
            log.error("Error checking round completion", e);
        }
    }

    private void startNextRound(Session session, int nextRoundNumber) {
        log.info("Starting round {} for session {}", nextRoundNumber, session.getId());

        // Update session current round
        session.setCurrentRound(nextRoundNumber);
        sessionRepository.save(session);

        // Get or create next round
        Round nextRound = roundRepository.findBySessionIdAndRoundNumber(
                session.getId(),
                nextRoundNumber
        ).orElseGet(() -> {
            Round newRound = new Round();
            newRound.setSession(session);
            newRound.setRoundNumber(nextRoundNumber);
            newRound.setStartTime(LocalDateTime.now());
            newRound.setTimerState(Round.TimerState.RUNNING);
            return roundRepository.save(newRound);
        });

        // If round exists but not started, start it
        if (nextRound.getStartTime() == null) {
            nextRound.setStartTime(LocalDateTime.now());
            nextRound.setTimerState(Round.TimerState.RUNNING);
            roundRepository.save(nextRound);
        }

        // Broadcast round_start event with previous ideas
        broadcastRoundStartEvent(session.getId(), nextRound, nextRoundNumber);
    }

    private void broadcastRoundStartEvent(Long sessionId, Round round, int roundNumber) {
        // Get previous round's ideas
        int previousRoundNumber = roundNumber - 1;
        List<com.brainstorming.entity.Idea> previousIdeas = previousRoundNumber > 0
            ? roundRepository.findBySessionIdAndRoundNumber(sessionId, previousRoundNumber)
                    .map(prevRound -> prevRound.getIdeas())
                    .orElse(List.of())
            : List.of();

        // Build the round object for the payload
        Map<String, Object> roundData = Map.of(
                "id", round.getId(),
                "session_id", sessionId,
                "round_number", round.getRoundNumber(),
                "start_time", round.getStartTime() != null ? round.getStartTime().toString() : null,
                "end_time", round.getEndTime() != null ? round.getEndTime().toString() : null,
                "timer_state", round.getTimerState().name(),
                "created_at", round.getCreatedAt() != null ? round.getCreatedAt().toString() : null
        );

        // Build previous ideas array
        List<Map<String, Object>> previousIdeasData = previousIdeas.stream()
                .map(idea -> {
                    Map<String, Object> ideaMap = new java.util.HashMap<>();
                    ideaMap.put("id", idea.getId());
                    ideaMap.put("session_id", sessionId);
                    ideaMap.put("round_id", idea.getRound().getId());
                    ideaMap.put("round_number", previousRoundNumber);
                    ideaMap.put("team_id", idea.getTeam().getId());
                    ideaMap.put("author_id", idea.getAuthor().getId());
                    ideaMap.put("author_name", idea.getAuthor().getFullName());
                    ideaMap.put("text", idea.getText());
                    ideaMap.put("passed_from_user_id", idea.getPassedFromUser() != null ? idea.getPassedFromUser().getId() : null);
                    ideaMap.put("passed_from_user_name", idea.getPassedFromUser() != null ? idea.getPassedFromUser().getFullName() : null);
                    ideaMap.put("created_at", idea.getCreatedAt().toString());
                    ideaMap.put("updated_at", idea.getUpdatedAt().toString());
                    return ideaMap;
                })
                .toList();

        // Broadcast round_start event to all participants
        broadcastToSession(sessionId, new WebSocketMessage("round_start", Map.of(
                "round", roundData,
                "previous_ideas", previousIdeasData,
                "timer_remaining_seconds", 60  // 1 minute timer
        )), null);
    }

    @SuppressWarnings("unchecked")
    private void handleSessionControl(WebSocketSession session, WebSocketMessage message, Long sessionId, Long userId) throws Exception {
        Map<String, Object> data = (Map<String, Object>) message.getPayload();
        String action = (String) data.get("action");

        try {
            SessionStateDto state = sessionService.controlSession(sessionId, userId, action);
            
            // Broadcast updated state to all participants
            broadcastToSession(sessionId, new WebSocketMessage("session_updated", state), null);
        } catch (Exception e) {
            log.error("Failed to control session", e);
            sendMessage(session, new WebSocketMessage("error", Map.of("message", e.getMessage())));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        log.info("WebSocket connection closed: {} with status {}", session.getId(), status);

        UserSessionInfo userInfo = sessionUserInfo.remove(session.getId());
        if (userInfo != null) {
            Long sessionId = userInfo.getSessionId();
            Map<String, WebSocketSession> sessions = sessionConnections.get(sessionId);
            if (sessions != null) {
                sessions.remove(session.getId());
                if (sessions.isEmpty()) {
                    sessionConnections.remove(sessionId);
                }
            }

            // Notify other participants
            broadcastToSession(sessionId, new WebSocketMessage("user_left", Map.of(
                    "userId", userInfo.getUserId(),
                    "userName", userInfo.getFullName()
            )), null);
        }
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        log.error("WebSocket transport error for session {}: {}", session.getId(), exception.getMessage());
    }

    public void broadcastSessionState(Long sessionId) {
        Map<String, WebSocketSession> sessions = sessionConnections.get(sessionId);
        if (sessions == null || sessions.isEmpty()) {
            return;
        }

        for (Map.Entry<String, WebSocketSession> entry : sessions.entrySet()) {
            WebSocketSession wsSession = entry.getValue();
            UserSessionInfo userInfo = sessionUserInfo.get(entry.getKey());
            if (userInfo != null && wsSession.isOpen()) {
                try {
                    SessionStateDto state = sessionService.getSessionState(sessionId, userInfo.getUserId());
                    sendMessage(wsSession, new WebSocketMessage("session_state", state));
                } catch (Exception e) {
                    log.error("Failed to broadcast session state to user {}", userInfo.getUserId(), e);
                }
            }
        }
    }

    public void broadcastToSession(Long sessionId, WebSocketMessage message, String excludeSessionId) {
        Map<String, WebSocketSession> sessions = sessionConnections.get(sessionId);
        if (sessions == null) {
            return;
        }

        for (Map.Entry<String, WebSocketSession> entry : sessions.entrySet()) {
            if (excludeSessionId != null && excludeSessionId.equals(entry.getKey())) {
                continue;
            }
            WebSocketSession wsSession = entry.getValue();
            if (wsSession.isOpen()) {
                try {
                    sendMessage(wsSession, message);
                } catch (Exception e) {
                    log.error("Failed to broadcast message to session {}", entry.getKey(), e);
                }
            }
        }
    }

    private void sendMessage(WebSocketSession session, WebSocketMessage message) throws IOException {
        if (session.isOpen()) {
            String json = objectMapper.writeValueAsString(message);
            session.sendMessage(new TextMessage(json));
        }
    }

    private Long extractSessionId(URI uri) {
        if (uri == null) return null;
        Matcher matcher = SESSION_ID_PATTERN.matcher(uri.getPath());
        if (matcher.find()) {
            try {
                return Long.parseLong(matcher.group(1));
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    private String extractToken(URI uri) {
        if (uri == null || uri.getQuery() == null) return null;
        String query = uri.getQuery();
        for (String param : query.split("&")) {
            String[] pair = param.split("=");
            if (pair.length == 2 && "token".equals(pair[0])) {
                return pair[1];
            }
        }
        return null;
    }

    private boolean isTokenInvalid(String token) {
        try {
            return jwtService.isTokenExpired(token);
        } catch (Exception e) {
            log.warn("Token validation failed: {}", e.getMessage());
            return true;
        }
    }

    @lombok.Data
    @lombok.AllArgsConstructor
    private static class UserSessionInfo {
        private Long userId;
        private String username;
        private String fullName;
        private Long sessionId;
    }

    @lombok.Data
    @lombok.AllArgsConstructor
    @lombok.NoArgsConstructor
    public static class WebSocketMessage {
        private String type;
        private Object payload;
    }
}
