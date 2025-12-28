"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { TimerState } from "@/types/session";

interface UseTimerOptions {
    initialSeconds: number;
    timerState: TimerState;
    isConnected: boolean;
    onExpire?: () => void;
}

interface UseTimerReturn {
    seconds: number;
    isExpired: boolean;
    reset: (newSeconds: number) => void;
}

export function useTimer({
    initialSeconds,
    timerState,
    isConnected,
    onExpire,
}: UseTimerOptions): UseTimerReturn {
    const [seconds, setSeconds] = useState(initialSeconds);
    const [isExpired, setIsExpired] = useState(false);
    const intervalRef = useRef<NodeJS.Timeout | null>(null);
    const onExpireRef = useRef(onExpire);

    // Keep onExpire callback ref updated
    useEffect(() => {
        onExpireRef.current = onExpire;
    }, [onExpire]);

    // Sync with server time
    useEffect(() => {
        setSeconds(initialSeconds);
        setIsExpired(initialSeconds <= 0);
    }, [initialSeconds]);

    // Timer countdown logic
    useEffect(() => {
        // Clear existing interval
        if (intervalRef.current) {
            clearInterval(intervalRef.current);
            intervalRef.current = null;
        }

        // Only run timer if connected, running, and not expired
        if (!isConnected || timerState !== TimerState.RUNNING || seconds <= 0) {
            return;
        }

        intervalRef.current = setInterval(() => {
            setSeconds((prev) => {
                const newValue = prev - 1;
                if (newValue <= 0) {
                    setIsExpired(true);
                    onExpireRef.current?.();
                    if (intervalRef.current) {
                        clearInterval(intervalRef.current);
                        intervalRef.current = null;
                    }
                    return 0;
                }
                return newValue;
            });
        }, 1000);

        return () => {
            if (intervalRef.current) {
                clearInterval(intervalRef.current);
                intervalRef.current = null;
            }
        };
    }, [isConnected, timerState, seconds]);

    const reset = useCallback((newSeconds: number) => {
        setSeconds(newSeconds);
        setIsExpired(newSeconds <= 0);
    }, []);

    return {
        seconds,
        isExpired,
        reset,
    };
}
