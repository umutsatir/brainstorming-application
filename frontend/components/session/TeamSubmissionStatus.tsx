"use client";

import { TeamMemberSubmissionStatus } from "@/types/session";

interface TeamSubmissionStatusProps {
    submissions: TeamMemberSubmissionStatus[];
    currentUserId: number;
}

export function TeamSubmissionStatus({
    submissions,
    currentUserId,
}: TeamSubmissionStatusProps) {
    const submittedCount = submissions.filter((s) => s.submitted).length;
    const totalCount = submissions.length;
    const allSubmitted = submittedCount === totalCount;

    return (
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-white flex items-center gap-2">
                    <svg
                        className="w-5 h-5 text-zinc-400"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                        />
                    </svg>
                    Team Progress
                </h2>
                <span
                    className={`text-sm font-medium px-2 py-1 rounded-full ${
                        allSubmitted
                            ? "bg-emerald-500/20 text-emerald-400"
                            : "bg-zinc-700 text-zinc-300"
                    }`}
                >
                    {submittedCount}/{totalCount} submitted
                </span>
            </div>

            {/* Progress bar */}
            <div className="h-2 bg-zinc-800 rounded-full overflow-hidden mb-4">
                <div
                    className={`h-full transition-all duration-500 ${
                        allSubmitted ? "bg-emerald-500" : "bg-blue-500"
                    }`}
                    style={{ width: `${(submittedCount / totalCount) * 100}%` }}
                />
            </div>

            {/* Member list */}
            <div className="space-y-2">
                {submissions.map((member) => {
                    const isCurrentUser = member.user_id === currentUserId;
                    
                    return (
                        <div
                            key={member.user_id}
                            className={`flex items-center justify-between p-3 rounded-lg transition-colors ${
                                member.submitted
                                    ? "bg-emerald-500/10 border border-emerald-500/20"
                                    : "bg-zinc-800/50 border border-zinc-700"
                            }`}
                        >
                            <div className="flex items-center gap-3">
                                <div
                                    className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                                        member.submitted
                                            ? "bg-emerald-500/20 text-emerald-400"
                                            : "bg-zinc-700 text-zinc-400"
                                    }`}
                                >
                                    {member.user_name.charAt(0).toUpperCase()}
                                </div>
                                <span
                                    className={`font-medium ${
                                        isCurrentUser ? "text-white" : "text-zinc-300"
                                    }`}
                                >
                                    {member.user_name}
                                    {isCurrentUser && (
                                        <span className="ml-2 text-xs text-zinc-500">(You)</span>
                                    )}
                                </span>
                            </div>
                            <div className="flex items-center gap-2">
                                {member.submitted ? (
                                    <>
                                        <svg
                                            className="w-5 h-5 text-emerald-400"
                                            fill="currentColor"
                                            viewBox="0 0 20 20"
                                        >
                                            <path
                                                fillRule="evenodd"
                                                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                                clipRule="evenodd"
                                            />
                                        </svg>
                                        <span className="text-sm text-emerald-400">Submitted</span>
                                    </>
                                ) : (
                                    <>
                                        <div className="w-5 h-5 flex items-center justify-center">
                                            <div className="w-2 h-2 bg-amber-400 rounded-full animate-pulse" />
                                        </div>
                                        <span className="text-sm text-amber-400">Pending</span>
                                    </>
                                )}
                            </div>
                        </div>
                    );
                })}
            </div>

            {allSubmitted && (
                <div className="mt-4 p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-center">
                    <p className="text-sm text-emerald-400">
                        ✨ All team members have submitted their ideas!
                    </p>
                </div>
            )}
        </div>
    );
}
