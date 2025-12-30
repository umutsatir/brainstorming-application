"use client";

import { SessionStatus } from "@/types/session";

interface SessionHeaderProps {
    teamName: string;
    topicTitle: string;
    currentRound: number;
    totalRounds: number;
    status: SessionStatus;
    isConnected: boolean;
}

export function SessionHeader({
    teamName,
    topicTitle,
    currentRound,
    totalRounds,
    status,
    isConnected,
}: SessionHeaderProps) {
    const getStatusBadge = () => {
        switch (status) {
            case SessionStatus.RUNNING:
                return (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-green-50 text-green-700 text-sm font-medium border border-green-200">
                        <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                        In Progress
                    </span>
                );
            case SessionStatus.PAUSED:
                return (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-50 text-amber-700 text-sm font-medium border border-amber-200">
                        <span className="w-2 h-2 bg-amber-500 rounded-full" />
                        Paused
                    </span>
                );
            case SessionStatus.PENDING:
                return (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-gray-50 text-gray-700 text-sm font-medium border border-gray-200">
                        <span className="w-2 h-2 bg-gray-500 rounded-full" />
                        Waiting to Start
                    </span>
                );
            case SessionStatus.COMPLETED:
                return (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 text-blue-700 text-sm font-medium border border-blue-200">
                        <span className="w-2 h-2 bg-blue-500 rounded-full" />
                        Completed
                    </span>
                );
            default:
                return null;
        }
    };

    return (
        <div className="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div>
                    <div className="flex items-center gap-3 mb-2">
                        <h1 className="text-2xl font-bold text-gray-900">{teamName}</h1>
                        {!isConnected && (
                            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 text-xs font-medium border border-amber-200">
                                <span className="w-1.5 h-1.5 bg-amber-500 rounded-full animate-pulse" />
                                Reconnecting
                            </span>
                        )}
                    </div>
                    <p className="text-gray-500 text-sm">
                        Topic: <span className="text-gray-900">{topicTitle}</span>
                    </p>
                </div>
                <div className="flex items-center gap-4">
                    <div className="text-right">
                        <div className="text-sm text-gray-500">Round</div>
                        <div className="text-2xl font-bold text-gray-900">
                            {currentRound}{" "}
                            <span className="text-gray-400 text-lg font-normal">
                                / {totalRounds}
                            </span>
                        </div>
                    </div>
                    <div className="w-px h-12 bg-gray-200" />
                    {getStatusBadge()}
                </div>
            </div>

            {/* Progress bar */}
            <div className="mt-4">
                <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                        className="h-full bg-gradient-to-r from-blue-600 to-indigo-600 transition-all duration-500"
                        style={{ width: `${(currentRound / totalRounds) * 100}%` }}
                    />
                </div>
            </div>
        </div>
    );
}
