"use client";

import { Idea } from "@/types/session";

interface PreviousIdeasProps {
    ideas: Idea[];
    authorName: string;
    roundNumber: number;
}

export function PreviousIdeas({ ideas, authorName, roundNumber }: PreviousIdeasProps) {
    if (roundNumber === 1) {
        return (
            <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
                <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
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
                            d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                        />
                    </svg>
                    Round 1 - Fresh Start
                </h2>
                <div className="bg-zinc-800/50 border border-zinc-700 rounded-lg p-6 text-center">
                    <div className="text-zinc-400 mb-2">
                        This is the first round. Create your own original ideas!
                    </div>
                    <div className="text-sm text-zinc-500">
                        In subsequent rounds, you'll build upon ideas from your teammates.
                    </div>
                </div>
            </div>
        );
    }

    if (ideas.length === 0) {
        return (
            <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
                <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
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
                            d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
                        />
                    </svg>
                    Ideas from Previous Round
                </h2>
                <div className="bg-zinc-800/50 border border-zinc-700 rounded-lg p-6 text-center">
                    <div className="text-zinc-400">
                        Waiting for ideas from your teammate...
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-1 flex items-center gap-2">
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
                        d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
                    />
                </svg>
                Build Upon These Ideas
            </h2>
            <p className="text-sm text-zinc-400 mb-4">
                From <span className="text-zinc-200 font-medium">{authorName}</span> in Round {roundNumber - 1}
            </p>

            <div className="space-y-3">
                {ideas.map((idea, index) => (
                    <div
                        key={idea.id}
                        className="bg-zinc-800/50 border border-zinc-700 rounded-lg p-4 hover:border-zinc-600 transition-colors"
                    >
                        <div className="flex items-start gap-3">
                            <div className="flex-shrink-0 w-8 h-8 bg-zinc-700 rounded-full flex items-center justify-center text-sm font-medium text-zinc-300">
                                {index + 1}
                            </div>
                            <p className="text-zinc-200 leading-relaxed">{idea.text}</p>
                        </div>
                    </div>
                ))}
            </div>

            <div className="mt-4 p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg">
                <p className="text-sm text-emerald-400">
                    💡 Tip: Use these ideas as inspiration. Expand, combine, or create variations!
                </p>
            </div>
        </div>
    );
}
