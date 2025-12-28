"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import {
    WsMessage,
    WsMessageType,
    SessionState,
    TimerTickPayload,
    RoundStartPayload,
    MemberSubmittedPayload,
    SubmitIdeasPayload,
} from "@/types/session";

interface UseSessionWebSocketOptions {
    sessionId: number;
    token: string;
    onSessionState?: (state: SessionState) => void;
    onTimerTick?: (payload: TimerTickPayload) => void;
    onRoundStart?: (payload: RoundStartPayload) => void;
    onRoundEnd?: () => void;
    onMemberSubmitted?: (payload: MemberSubmittedPayload) => void;
    onSessionPaused?: () => void;
    onSessionResumed?: () => void;
    onSessionCompleted?: () => void;
    onError?: (error: string) => void;
    onConnectionChange?: (connected: boolean) => void;
}

interface UseSessionWebSocketReturn {
    isConnected: boolean;
    isReconnecting: boolean;
    submitIdeas: (payload: SubmitIdeasPayload) => void;
    requestSync: () => void;
    disconnect: () => void;
}

const WS_BASE_URL = process.env.NEXT_PUBLIC_WS_URL || "ws://localhost:8080/ws/sessions";
const RECONNECT_DELAY = 3000;
const MAX_RECONNECT_ATTEMPTS = 5;

export function useSessionWebSocket(
    options: UseSessionWebSocketOptions
): UseSessionWebSocketReturn {
    const {
        sessionId,
        token,
        onSessionState,
        onTimerTick,
        onRoundStart,
        onRoundEnd,
        onMemberSubmitted,
        onSessionPaused,
        onSessionResumed,
        onSessionCompleted,
        onError,
        onConnectionChange,
    } = options;

    const [isConnected, setIsConnected] = useState(false);
    const [isReconnecting, setIsReconnecting] = useState(false);

    const wsRef = useRef<WebSocket | null>(null);
    const reconnectAttemptsRef = useRef(0);
    const reconnectTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const shouldReconnectRef = useRef(true);

    const handleMessage = useCallback(
        (event: MessageEvent) => {
            try {
                const message = JSON.parse(event.data);
                const messageType = message.type as string;

                switch (messageType) {
                    case WsMessageType.SESSION_STATE:
                    case WsMessageType.SYNC_RESPONSE:
                    case "session_state":
                    case "session_updated":
                        onSessionState?.(message.payload as SessionState);
                        break;

                    case WsMessageType.TIMER_TICK:
                        onTimerTick?.(message.payload as TimerTickPayload);
                        break;

                    case WsMessageType.ROUND_START:
                        onRoundStart?.(message.payload as RoundStartPayload);
                        break;

                    case WsMessageType.ROUND_END:
                        onRoundEnd?.();
                        break;

                    case WsMessageType.MEMBER_SUBMITTED:
                    case "ideas_submitted":
                        onMemberSubmitted?.(message.payload as MemberSubmittedPayload);
                        break;

                    case WsMessageType.SESSION_PAUSED:
                        onSessionPaused?.();
                        break;

                    case WsMessageType.SESSION_RESUMED:
                        onSessionResumed?.();
                        break;

                    case WsMessageType.SESSION_COMPLETED:
                        onSessionCompleted?.();
                        break;

                    case WsMessageType.ERROR:
                    case "error":
                        onError?.(message.payload?.message || "Unknown error");
                        break;

                    case "user_joined":
                    case "user_left":
                    case "pong":
                        // Handle these silently
                        break;

                    default:
                        console.warn("Unknown WebSocket message type:", message.type);
                }
            } catch (err) {
                console.error("Failed to parse WebSocket message:", err);
            }
        },
        [
            onSessionState,
            onTimerTick,
            onRoundStart,
            onRoundEnd,
            onMemberSubmitted,
            onSessionPaused,
            onSessionResumed,
            onSessionCompleted,
            onError,
        ]
    );

    const connect = useCallback(() => {
        if (wsRef.current?.readyState === WebSocket.OPEN) {
            return;
        }

        // Connect to Spring Boot WebSocket - format: /ws/sessions/{sessionId}?token=xxx
        const wsUrl = `${WS_BASE_URL}/${sessionId}?token=${token}`;
        const ws = new WebSocket(wsUrl);

        ws.onopen = () => {
            console.log("WebSocket connected");
            setIsConnected(true);
            setIsReconnecting(false);
            reconnectAttemptsRef.current = 0;
            onConnectionChange?.(true);
            // Backend sends initial state on connection, no need to send join message
        };

        ws.onmessage = handleMessage;

        ws.onclose = (event) => {
            console.log("WebSocket closed:", event.code, event.reason);
            setIsConnected(false);
            onConnectionChange?.(false);

            if (
                shouldReconnectRef.current &&
                reconnectAttemptsRef.current < MAX_RECONNECT_ATTEMPTS
            ) {
                setIsReconnecting(true);
                reconnectAttemptsRef.current += 1;
                console.log(
                    `Reconnecting... attempt ${reconnectAttemptsRef.current}/${MAX_RECONNECT_ATTEMPTS}`
                );

                reconnectTimeoutRef.current = setTimeout(() => {
                    connect();
                }, RECONNECT_DELAY);
            } else if (reconnectAttemptsRef.current >= MAX_RECONNECT_ATTEMPTS) {
                setIsReconnecting(false);
                onError?.("Failed to reconnect after multiple attempts");
            }
        };

        ws.onerror = (error) => {
            console.error("WebSocket error:", error);
            onError?.("WebSocket connection error");
        };

        wsRef.current = ws;
    }, [sessionId, token, handleMessage, onConnectionChange, onError]);

    const disconnect = useCallback(() => {
        shouldReconnectRef.current = false;

        if (reconnectTimeoutRef.current) {
            clearTimeout(reconnectTimeoutRef.current);
            reconnectTimeoutRef.current = null;
        }

        if (wsRef.current) {
            // Send leave message before closing
            if (wsRef.current.readyState === WebSocket.OPEN) {
                const leaveMessage: WsMessage = {
                    type: WsMessageType.LEAVE_SESSION,
                    payload: { session_id: sessionId },
                    timestamp: new Date().toISOString(),
                };
                wsRef.current.send(JSON.stringify(leaveMessage));
            }
            wsRef.current.close();
            wsRef.current = null;
        }

        setIsConnected(false);
        setIsReconnecting(false);
    }, [sessionId]);

    const submitIdeas = useCallback((payload: SubmitIdeasPayload) => {
        if (wsRef.current?.readyState === WebSocket.OPEN) {
            const message: WsMessage = {
                type: WsMessageType.SUBMIT_IDEAS,
                payload,
                timestamp: new Date().toISOString(),
            };
            wsRef.current.send(JSON.stringify(message));
        } else {
            onError?.("Not connected. Please wait for reconnection.");
        }
    }, [onError]);

    const requestSync = useCallback(() => {
        if (wsRef.current?.readyState === WebSocket.OPEN) {
            const message: WsMessage = {
                type: WsMessageType.SYNC_REQUEST,
                payload: { session_id: sessionId },
                timestamp: new Date().toISOString(),
            };
            wsRef.current.send(JSON.stringify(message));
        }
    }, [sessionId]);

    // Connect on mount
    useEffect(() => {
        shouldReconnectRef.current = true;
        connect();

        return () => {
            disconnect();
        };
    }, [connect, disconnect]);

    // Request sync on reconnection
    useEffect(() => {
        if (isConnected && reconnectAttemptsRef.current > 0) {
            requestSync();
        }
    }, [isConnected, requestSync]);

    return {
        isConnected,
        isReconnecting,
        submitIdeas,
        requestSync,
        disconnect,
    };
}
