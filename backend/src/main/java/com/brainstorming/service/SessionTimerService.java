package com.brainstorming.service;

import com.brainstorming.entity.Idea;
import com.brainstorming.entity.Round;
import com.brainstorming.entity.Session;
import com.brainstorming.repository.RoundRepository;
import com.brainstorming.repository.SessionRepository;
import com.brainstorming.websocket.SessionWebSocketHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class SessionTimerService {

    private final SessionRepository sessionRepository;
    private final RoundRepository roundRepository;
    private final SessionWebSocketHandler webSocketHandler;
    private final SessionService sessionService;

    private static final long ROUND_DURATION_SECONDS = 60; // 1 minute (for testing)

    /**
     * Runs every second to update timers for active sessions
     */
    @Scheduled(fixedRate = 1000)
    @Transactional
    public void updateTimers() {
        List<Session> runningSessions = sessionRepository.findByStatus(Session.Status.RUNNING);

        for (Session session : runningSessions) {
            try {
                processSessionTimer(session);
            } catch (Exception e) {
                log.error("Error processing timer for session {}", session.getId(), e);
            }
        }
    }

    private void processSessionTimer(Session session) {
        Round currentRound = roundRepository.findBySessionIdAndRoundNumber(
                session.getId(),
                session.getCurrentRound()
        ).orElse(null);

        if (currentRound == null || currentRound.getTimerState() != Round.TimerState.RUNNING) {
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime startTime = currentRound.getStartTime();

        if (startTime == null) {
            return;
        }

        // Calculate elapsed and remaining time
        long elapsedSeconds = ChronoUnit.SECONDS.between(startTime, now);
        long remainingSeconds = ROUND_DURATION_SECONDS - elapsedSeconds;

        if (remainingSeconds <= 0) {
            // Timer expired - lock the round and progress to next round
            handleRoundTimeout(session, currentRound);
        } else {
            // Broadcast timer tick every second
            broadcastTimerTick(session.getId(), remainingSeconds, Round.TimerState.RUNNING);
        }
    }

    /**
     * Public method to advance round when all users have submitted
     * Can be called from WebSocket handler
     */
    public void advanceRound(Long sessionId, Integer currentRoundNumber) {
        Session session = sessionRepository.findById(sessionId).orElse(null);
        if (session == null) {
            return;
        }

        Round currentRound = roundRepository.findBySessionIdAndRoundNumber(sessionId, currentRoundNumber).orElse(null);
        if (currentRound == null) {
            return;
        }

        handleRoundCompletion(session, currentRound);
    }

    private void handleRoundTimeout(Session session, Round currentRound) {
        log.info("Round {} timeout for session {}", currentRound.getRoundNumber(), session.getId());
        handleRoundCompletion(session, currentRound);
    }

    private void handleRoundCompletion(Session session, Round currentRound) {
        // Mark timer as finished
        currentRound.setTimerState(Round.TimerState.FINISHED);
        currentRound.setEndTime(LocalDateTime.now());
        roundRepository.save(currentRound);

        // Check if this was the last round
        if (currentRound.getRoundNumber() >= session.getRoundCount()) {
            // Session is complete
            completeSession(session);
        } else {
            // Start next round
            startNextRound(session, currentRound.getRoundNumber() + 1);
        }

        // Signal all clients to refresh their state
        webSocketHandler.broadcastToSession(
                session.getId(),
                new SessionWebSocketHandler.WebSocketMessage("refresh_state", Map.of(
                        "message", "Round completed, please refresh state"
                )),
                null
        );
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

        log.info("Next round {} created and started for session {}", nextRoundNumber, session.getId());
    }

    private void completeSession(Session session) {
        log.info("Completing session {}", session.getId());

        session.setStatus(Session.Status.COMPLETED);
        sessionRepository.save(session);

        // Broadcast session completed event
        webSocketHandler.broadcastToSession(
                session.getId(),
                new SessionWebSocketHandler.WebSocketMessage("session_completed", Map.of(
                        "sessionId", session.getId(),
                        "message", "Brainstorming session completed!"
                )),
                null
        );
    }

    private void broadcastTimerTick(Long sessionId, long remainingSeconds, Round.TimerState timerState) {
        webSocketHandler.broadcastToSession(
                sessionId,
                new SessionWebSocketHandler.WebSocketMessage("timer_tick", Map.of(
                        "remaining_seconds", remainingSeconds,
                        "timer_state", timerState.name()
                )),
                null
        );
    }
}
