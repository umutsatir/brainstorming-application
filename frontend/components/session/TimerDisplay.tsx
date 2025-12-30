"use client";

import { TimerState } from "@/types/session";
import { useEffect, useState } from "react";

interface TimerDisplayProps {
    remainingSeconds: number;
    timerState: TimerState;
    isConnected: boolean;
}

export function TimerDisplay({
    remainingSeconds,
    timerState,
    isConnected,
}: TimerDisplayProps) {
    const [displaySeconds, setDisplaySeconds] = useState(remainingSeconds);

    useEffect(() => {
        setDisplaySeconds(remainingSeconds);
    }, [remainingSeconds]);

    // Local countdown when connected and timer is running
    useEffect(() => {
        if (!isConnected || timerState !== TimerState.RUNNING || displaySeconds <= 0) {
            return;
        }

        const interval = setInterval(() => {
            setDisplaySeconds((prev) => Math.max(0, prev - 1));
        }, 1000);

        return () => clearInterval(interval);
    }, [isConnected, timerState, displaySeconds]);

    const minutes = Math.floor(displaySeconds / 60);
    const seconds = displaySeconds % 60;

    const isLowTime = displaySeconds <= 60;
    const isCritical = displaySeconds <= 30;

    const getTimerColor = () => {
        if (timerState === TimerState.FINISHED) return "text-gray-400";
        if (timerState === TimerState.PAUSED) return "text-amber-600";
        if (isCritical) return "text-red-600 animate-pulse";
        if (isLowTime) return "text-amber-600";
        return "text-blue-600";
    };

    const getStatusText = () => {
        if (timerState === TimerState.FINISHED) return "Time's up!";
        if (timerState === TimerState.PAUSED) return "Paused";
        if (!isConnected) return "Reconnecting...";
        return null;
    };

    const statusText = getStatusText();

    return (
        <div className="flex flex-col items-center">
            <div className="text-sm font-medium text-gray-500 uppercase tracking-wider mb-2">
                Time Remaining
            </div>
            <div
                className={`text-6xl font-bold font-mono tabular-nums ${getTimerColor()} transition-colors duration-300`}
            >
                {String(minutes).padStart(2, "0")}:{String(seconds).padStart(2, "0")}
            </div>
            {statusText && (
                <div
                    className={`mt-2 text-sm font-medium ${
                        timerState === TimerState.FINISHED
                            ? "text-gray-400"
                            : timerState === TimerState.PAUSED
                            ? "text-amber-600"
                            : "text-gray-500"
                    }`}
                >
                    {statusText}
                </div>
            )}
            {!isConnected && (
                <div className="mt-2 flex items-center gap-2 text-amber-600">
                    <div className="w-2 h-2 bg-amber-500 rounded-full animate-pulse" />
                    <span className="text-sm">Syncing...</span>
                </div>
            )}
        </div>
    );
}
