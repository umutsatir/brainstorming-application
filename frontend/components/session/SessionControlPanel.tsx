"use client";

import { useState } from "react";
import { SessionStatus } from "@/types/session";
import { API_BASE_URL } from "@/lib/config";

interface SessionControlPanelProps {
    sessionId: number;
    status: SessionStatus;
    token: string;
    onStatusChange: (newStatus: SessionStatus) => void;
}

export function SessionControlPanel({
    sessionId,
    status,
    token,
    onStatusChange,
}: SessionControlPanelProps) {
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleAction = async (action: "start" | "pause" | "resume" | "end") => {
        try {
            setIsLoading(true);
            setError(null);

            const response = await fetch(`${API_BASE_URL}/sessions/${sessionId}/control`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({ action }),
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || "Failed to control session");
            }

            onStatusChange(data.session.status as SessionStatus);
        } catch (err: any) {
            setError(err.message);
        } finally {
            setIsLoading(false);
        }
    };

    const getAvailableActions = () => {
        switch (status) {
            case SessionStatus.PENDING:
                return [{ action: "start" as const, label: "Start Session", color: "emerald" }];
            case SessionStatus.RUNNING:
                return [
                    { action: "pause" as const, label: "Pause", color: "amber" },
                    { action: "end" as const, label: "End Session", color: "red" },
                ];
            case SessionStatus.PAUSED:
                return [
                    { action: "resume" as const, label: "Resume", color: "emerald" },
                    { action: "end" as const, label: "End Session", color: "red" },
                ];
            case SessionStatus.COMPLETED:
                return [];
            default:
                return [];
        }
    };

    const actions = getAvailableActions();

    if (actions.length === 0) {
        return null;
    }

    const getButtonClasses = (color: string) => {
        const baseClasses = "px-4 py-2 rounded-lg font-medium text-sm transition-all flex items-center gap-2";

        if (isLoading) {
            return `${baseClasses} bg-gray-200 text-gray-400 cursor-not-allowed`;
        }

        switch (color) {
            case "emerald":
                return `${baseClasses} bg-green-600 hover:bg-green-700 text-white`;
            case "amber":
                return `${baseClasses} bg-amber-500 hover:bg-amber-600 text-white`;
            case "red":
                return `${baseClasses} bg-red-500 hover:bg-red-600 text-white`;
            default:
                return `${baseClasses} bg-gray-600 hover:bg-gray-700 text-white`;
        }
    };

    const getIcon = (action: string) => {
        switch (action) {
            case "start":
            case "resume":
                return (
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path
                            fillRule="evenodd"
                            d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
                            clipRule="evenodd"
                        />
                    </svg>
                );
            case "pause":
                return (
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path
                            fillRule="evenodd"
                            d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zM7 8a1 1 0 012 0v4a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v4a1 1 0 102 0V8a1 1 0 00-1-1z"
                            clipRule="evenodd"
                        />
                    </svg>
                );
            case "end":
                return (
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path
                            fillRule="evenodd"
                            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8 7a1 1 0 00-1 1v4a1 1 0 001 1h4a1 1 0 001-1V8a1 1 0 00-1-1H8z"
                            clipRule="evenodd"
                        />
                    </svg>
                );
            default:
                return null;
        }
    };

    return (
        <div className="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-4 flex items-center gap-2">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path
                        fillRule="evenodd"
                        d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z"
                        clipRule="evenodd"
                    />
                </svg>
                Session Control
            </h3>
            
            <div className="flex flex-wrap gap-3">
                {actions.map(({ action, label, color }) => (
                    <button
                        key={action}
                        onClick={() => handleAction(action)}
                        disabled={isLoading}
                        className={getButtonClasses(color)}
                    >
                        {isLoading ? (
                            <svg
                                className="animate-spin h-4 w-4"
                                fill="none"
                                viewBox="0 0 24 24"
                            >
                                <circle
                                    className="opacity-25"
                                    cx="12"
                                    cy="12"
                                    r="10"
                                    stroke="currentColor"
                                    strokeWidth="4"
                                />
                                <path
                                    className="opacity-75"
                                    fill="currentColor"
                                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                />
                            </svg>
                        ) : (
                            getIcon(action)
                        )}
                        {label}
                    </button>
                ))}
            </div>

            {error && (
                <div className="mt-3 p-2 bg-red-50 border border-red-200 rounded-lg">
                    <p className="text-sm text-red-600">{error}</p>
                </div>
            )}

            <div className="mt-4 text-xs text-gray-500">
                {status === SessionStatus.PENDING && (
                    <p>Start the session when all team members are ready.</p>
                )}
                {status === SessionStatus.RUNNING && (
                    <p>Session is active. You can pause or end it at any time.</p>
                )}
                {status === SessionStatus.PAUSED && (
                    <p>Session is paused. Resume when ready to continue.</p>
                )}
            </div>
        </div>
    );
}
