package com.brainstorming.websocket;

import com.brainstorming.dto.*;
import com.brainstorming.service.JwtService;
import com.brainstorming.service.SessionService;
import com.brainstorming.service.IdeaService;
import com.brainstorming.repository.UserRepository;
import com.brainstorming.entity.User;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.net.URI;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
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
            sendMessage(session, new WebSocketMessage("ideas_submitted", response));

            // Broadcast updated session state to all participants
            broadcastSessionState(sessionId);
        } catch (Exception e) {
            log.error("Failed to submit ideas", e);
            sendMessage(session, new WebSocketMessage("error", Map.of("message", e.getMessage())));
        }
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

    private void broadcastToSession(Long sessionId, WebSocketMessage message, String excludeSessionId) {
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
