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
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-400 text-sm font-medium">
                        <span className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse" />
                        In Progress
                    </span>
                );
            case SessionStatus.PAUSED:
                return (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-500/20 text-amber-400 text-sm font-medium">
                        <span className="w-2 h-2 bg-amber-400 rounded-full" />
                        Paused
                    </span>
                );
            case SessionStatus.PENDING:
                return (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-zinc-500/20 text-zinc-400 text-sm font-medium">
                        <span className="w-2 h-2 bg-zinc-400 rounded-full" />
                        Waiting to Start
                    </span>
                );
            case SessionStatus.COMPLETED:
                return (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-500/20 text-blue-400 text-sm font-medium">
                        <span className="w-2 h-2 bg-blue-400 rounded-full" />
                        Completed
                    </span>
                );
            default:
                return null;
        }
    };

    return (
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div>
                    <div className="flex items-center gap-3 mb-2">
                        <h1 className="text-2xl font-bold text-white">{teamName}</h1>
                        {!isConnected && (
                            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400 text-xs font-medium">
                                <span className="w-1.5 h-1.5 bg-amber-400 rounded-full animate-pulse" />
                                Reconnecting
                            </span>
                        )}
                    </div>
                    <p className="text-zinc-400 text-sm">
                        Topic: <span className="text-zinc-200">{topicTitle}</span>
                    </p>
                </div>
                <div className="flex items-center gap-4">
                    <div className="text-right">
                        <div className="text-sm text-zinc-400">Round</div>
                        <div className="text-2xl font-bold text-white">
                            {currentRound}{" "}
                            <span className="text-zinc-500 text-lg font-normal">
                                / {totalRounds}
                            </span>
                        </div>
                    </div>
                    <div className="w-px h-12 bg-zinc-700" />
                    {getStatusBadge()}
                </div>
            </div>
            
            {/* Progress bar */}
            <div className="mt-4">
                <div className="h-2 bg-zinc-800 rounded-full overflow-hidden">
                    <div
                        className="h-full bg-gradient-to-r from-emerald-500 to-emerald-400 transition-all duration-500"
                        style={{ width: `${(currentRound / totalRounds) * 100}%` }}
                    />
                </div>
            </div>
        </div>
    );
}
