"use client";

import { useState, useEffect, useCallback, useMemo } from "react";
import { useParams, useRouter } from "next/navigation";
import {
    Session,
    Round,
    Idea,
    SessionStatus,
    TimerState,
    TeamMemberSubmissionStatus,
    SessionState,
    TimerTickPayload,
    RoundStartPayload,
    MemberSubmittedPayload,
} from "@/types/session";
import { useSessionWebSocket } from "@/hooks/useSessionWebSocket";
import { API_BASE_URL } from "@/lib/config";
import {
    TimerDisplay,
    SessionHeader,
    PreviousIdeas,
    IdeaInputForm,
    TeamSubmissionStatus,
    ConnectionStatus,
    SessionControlPanel,
} from "@/components/session";

interface SessionPageClientProps {
    sessionId: number;
    token: string;
    currentUserId: number;
    userRole: "member" | "leader" | "manager";
}

export function SessionPageClient({
    sessionId,
    token,
    currentUserId,
    userRole,
}: SessionPageClientProps) {
    const router = useRouter();

    // Session state
    const [session, setSession] = useState<Session | null>(null);
    const [currentRound, setCurrentRound] = useState<Round | null>(null);
    const [timerRemaining, setTimerRemaining] = useState(300);
    const [previousIdeas, setPreviousIdeas] = useState<Idea[]>([]);
    const [myIdeas, setMyIdeas] = useState<Idea[]>([]);
    const [teamSubmissions, setTeamSubmissions] = useState<TeamMemberSubmissionStatus[]>([]);
    const [canSubmit, setCanSubmit] = useState(false);
    const [isRoundLocked, setIsRoundLocked] = useState(false);

    // UI state
    const [isLoading, setIsLoading] = useState(true);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [submitError, setSubmitError] = useState<string | null>(null);
    const [isWaitingForNextRound, setIsWaitingForNextRound] = useState(false);

    // Log when all team members submit (backend will auto-advance the round)
    useEffect(() => {
        var isAllSubmitted = true;
        teamSubmissions.forEach(submission => {
            if (!submission.submitted) {
                isAllSubmitted = false;
                return;
            }
        });
        if (isAllSubmitted && teamSubmissions.length > 0 && session?.status === SessionStatus.RUNNING) {
            console.log('All team members submitted - backend will auto-advance round');
            // Don't fetch state here - the backend will send round_end then round_start events
        }
    }, [teamSubmissions, session?.status]);

    // Fetch initial state
    const fetchSessionState = useCallback(async () => {
        try {
            setIsLoading(true);
            setError(null);

            const response = await fetch(`${API_BASE_URL}/sessions/${sessionId}/state`, {
                headers: {
                    Authorization: `Bearer ${token}`,
                },
            });

            if (!response.ok) {
                const data = await response.json();
                throw new Error(data.error || "Failed to load session");
            }

            const data = await response.json();
            handleSessionState(data);
            console.log("Fetched session state:", data);
        } catch (err: any) {
            setError(err.message);
        } finally {
            setIsLoading(false);
        }
    }, [sessionId, token]);

    // Handle session state update
    const handleSessionState = useCallback((state: SessionState) => {
        setSession(state.session);
        setCurrentRound(state.current_round);
        setTimerRemaining(state.timer_remaining_seconds);
        setPreviousIdeas(state.previous_ideas);
        setMyIdeas(state.my_ideas);
        setTeamSubmissions(state.team_submissions);
        setCanSubmit(state.can_submit);
        setIsRoundLocked(state.is_round_locked);
    }, []);

    // Handle timer tick
    const handleTimerTick = useCallback((payload: TimerTickPayload) => {
        setTimerRemaining(payload.remaining_seconds);
        if (payload.remaining_seconds === 0) {
            console.log('Timer reached 0, state:', payload.timer_state);
        }
        if (payload.timer_state === TimerState.FINISHED) {
            console.log('Timer FINISHED state received');
            setIsRoundLocked(true);
            setCanSubmit(false);
        }
    }, []);

    // Handle round start - not used anymore, backend sends refresh_state instead
    const handleRoundStart = useCallback((payload: RoundStartPayload) => {
        console.log('Round start event received (unused):', payload);
    }, []);

    // Handle round end - not used anymore, backend sends refresh_state instead
    const handleRoundEnd = useCallback(() => {
        console.log('Round end event received');
    }, []);

    // Handle member submitted
    const handleMemberSubmitted = useCallback((payload: any) => {
        // Check if this is a confirmation response (has 'ideas' field) or broadcast (has 'user_id')
        if (payload.ideas) {
            // This is the submitter's confirmation - update their ideas
            setMyIdeas(payload.ideas);
            setCanSubmit(false);
        } else if (payload.user_id !== undefined) {
            // This is a broadcast notification about someone's submission
            setTeamSubmissions((prev) =>
                prev.map((s) =>
                    s.user_id === payload.user_id
                        ? { ...s, submitted: true, submitted_at: new Date().toISOString() }
                        : s
                )
            );

            // If this is the current user's submission, disable further submissions
            if (payload.user_id === currentUserId) {
                setCanSubmit(false);
            }
        }
    }, [currentUserId]);

    // Handle session paused
    const handleSessionPaused = useCallback(() => {
        setSession((prev) =>
            prev ? { ...prev, status: SessionStatus.PAUSED } : null
        );
        setCanSubmit(false);
    }, []);

    // Handle session resumed
    const handleSessionResumed = useCallback(() => {
        setSession((prev) =>
            prev ? { ...prev, status: SessionStatus.RUNNING } : null
        );
        // Re-enable submit if conditions are met (for members and leaders)
        if ((userRole === "member" || userRole === "leader") && myIdeas.length === 0 && !isRoundLocked) {
            setCanSubmit(true);
        }
    }, [userRole, myIdeas.length, isRoundLocked]);

    // Handle session completed
    const handleSessionCompleted = useCallback(() => {
        setSession((prev) =>
            prev ? { ...prev, status: SessionStatus.COMPLETED } : null
        );
        setCanSubmit(false);
        setIsRoundLocked(true);
    }, []);

    // Handle refresh state signal from backend
    const handleRefreshState = useCallback(() => {
        console.log('Backend signaled to refresh state');
        setIsWaitingForNextRound(false);
        fetchSessionState();
    }, [fetchSessionState]);

    // Handle WebSocket error
    const handleWsError = useCallback((errorMsg: string) => {
        console.error("WebSocket error:", errorMsg);
    }, []);

    // WebSocket connection
    const {
        isConnected,
        isReconnecting,
        submitIdeas: wsSubmitIdeas,
        requestSync,
    } = useSessionWebSocket({
        sessionId,
        token,
        onSessionState: handleSessionState,
        onTimerTick: handleTimerTick,
        onRoundStart: handleRoundStart,
        onRoundEnd: handleRoundEnd,
        onMemberSubmitted: handleMemberSubmitted,
        onSessionPaused: handleSessionPaused,
        onSessionResumed: handleSessionResumed,
        onSessionCompleted: handleSessionCompleted,
        onRefreshState: handleRefreshState,
        onError: handleWsError,
    });

    // Initial fetch
    useEffect(() => {
        fetchSessionState();
    }, [fetchSessionState]);

    useEffect(() => {
        let isAllSubmitted = true;
        teamSubmissions.forEach(submission => {
            if (!submission.submitted) {
                isAllSubmitted = false;
                return;
            }
        });
        if (isAllSubmitted && teamSubmissions.length > 0 && session?.status === SessionStatus.RUNNING) {
            fetchSessionState();
        }
    }, [teamSubmissions]);

    // Submit ideas handler
    const handleSubmitIdeas = useCallback(
        async (ideas: string[]) => {
            if (!session || !currentRound) return;

            try {
                setIsSubmitting(true);
                setSubmitError(null);

                // Send via WebSocket - backend will handle submission and broadcast
                wsSubmitIdeas({
                    session_id: sessionId,
                    round_number: currentRound.round_number,
                    ideas,
                });

                // Don't update local state here - wait for WebSocket broadcast confirmation
                // The handleMemberSubmitted callback will update the UI for everyone including sender
            } catch (err: any) {
                setSubmitError(err.message);
            } finally {
                setIsSubmitting(false);
            }
        },
        [session, currentRound, sessionId, wsSubmitIdeas]
    );

    // Handle session status change from control panel
    const handleSessionStatusChange = useCallback((newStatus: SessionStatus) => {
        setSession((prev) => (prev ? { ...prev, status: newStatus } : null));
        
        // Update canSubmit based on new status
        if (newStatus === SessionStatus.RUNNING) {
            if ((userRole === "member" || userRole === "leader") && myIdeas.length === 0 && !isRoundLocked) {
                setCanSubmit(true);
            }
        } else {
            setCanSubmit(false);
        }
    }, [userRole, myIdeas.length, isRoundLocked]);

    // Previous ideas author name
    const previousAuthorName = useMemo(() => {
        if (previousIdeas.length === 0) return "";
        return previousIdeas[0].author_name;
    }, [previousIdeas]);

    // Check if current user has submitted
    const hasSubmitted = myIdeas.length >= 3;

    // Submitted idea texts
    const submittedIdeaTexts = useMemo(() => {
        return myIdeas.map((idea) => idea.text);
    }, [myIdeas]);

    // Timer state
    const timerState = currentRound?.timer_state || TimerState.RUNNING;

    // Determine if input should be disabled (members and leaders can submit, only managers are view-only)
    const isInputDisabled = useMemo(() => {
        return (
            !isConnected ||
            !session ||
            session.status !== SessionStatus.RUNNING ||
            isRoundLocked ||
            userRole === "manager"
        );
    }, [isConnected, session, isRoundLocked, userRole]);

    // Loading state
    if (isLoading) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center">
                <div className="flex flex-col items-center gap-4">
                    <svg
                        className="animate-spin h-10 w-10 text-emerald-400"
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
                    <p className="text-zinc-400">Loading session...</p>
                </div>
            </div>
        );
    }

    // Error state
    if (error || !session) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center">
                <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-8 max-w-md text-center">
                    <svg
                        className="w-12 h-12 text-red-400 mx-auto mb-4"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                    >
                        <path
                            fillRule="evenodd"
                            d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                            clipRule="evenodd"
                        />
                    </svg>
                    <h2 className="text-xl font-semibold text-white mb-2">Unable to Load Session</h2>
                    <p className="text-zinc-400 mb-6">{error || "Session not found"}</p>
                    <button
                        onClick={fetchSessionState}
                        className="px-6 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg font-medium transition-colors"
                    >
                        Try Again
                    </button>
                </div>
            </div>
        );
    }

    // Session completed state
    if (session.status === SessionStatus.COMPLETED) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center">
                <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-8 max-w-md text-center">
                    <svg
                        className="w-12 h-12 text-emerald-400 mx-auto mb-4"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                    >
                        <path
                            fillRule="evenodd"
                            d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                            clipRule="evenodd"
                        />
                    </svg>
                    <h2 className="text-xl font-semibold text-white mb-2">Session Completed!</h2>
                    <p className="text-zinc-400 mb-6">
                        Great work! The brainstorming session has ended.
                    </p>
                    <div className="flex flex-col gap-3">
                        {userRole === "member" ? (
                            <button
                                onClick={() => router.push("/")}
                                className="px-6 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg font-medium transition-colors"
                            >
                                Go to Main Page
                            </button>
                        ) : (
                            <>
                                <button
                                    onClick={() => router.push(`/sessions/${sessionId}/summary`)}
                                    className="px-6 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg font-medium transition-colors"
                                >
                                    View Session Summary
                                </button>
                                <button
                                    onClick={() => router.push("/dashboard")}
                                    className="px-6 py-2 bg-zinc-700 hover:bg-zinc-600 text-white rounded-lg font-medium transition-colors"
                                >
                                    Go to Dashboard
                                </button>
                            </>
                        )}
                    </div>
                </div>
            </div>
        );
    }

    // View-only mode only for event managers (leaders can submit ideas)
    const isViewOnly = userRole === "manager";
    
    // Can control session (leaders and managers)
    const canControlSession = userRole === "leader" || userRole === "manager";

    return (
        <div className="min-h-screen bg-black">
            <div className="max-w-6xl mx-auto px-4 py-8">
                {/* View-only banner for managers only */}
                {isViewOnly && (
                    <div className="mb-6 p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
                        <div className="flex items-center gap-3">
                            <svg
                                className="w-5 h-5 text-blue-400"
                                fill="currentColor"
                                viewBox="0 0 20 20"
                            >
                                <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
                                <path
                                    fillRule="evenodd"
                                    d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z"
                                    clipRule="evenodd"
                                />
                            </svg>
                            <p className="text-sm text-blue-400">
                                <span className="font-semibold">View-only mode.</span> As an event manager, you can
                                observe the session but cannot submit ideas.
                            </p>
                        </div>
                    </div>
                )}

                {/* Header */}
                <SessionHeader
                    teamName={session.team_name}
                    topicTitle={session.topic_title}
                    currentRound={session.current_round}
                    totalRounds={session.round_count}
                    status={session.status}
                    isConnected={isConnected}
                />

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
                    {/* Main content - 2 columns */}
                    <div className="lg:col-span-2 space-y-6">
                        {/* Timer or Waiting for Next Round */}
                        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-8">
                            {isWaitingForNextRound ? (
                                <div className="text-center">
                                    <div className="flex items-center justify-center gap-3 mb-2">
                                        <svg
                                            className="animate-spin h-8 w-8 text-emerald-400"
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
                                        <h3 className="text-2xl font-bold text-emerald-400">Preparing Next Round...</h3>
                                    </div>
                                    <p className="text-zinc-400">Please wait while we set up the next round</p>
                                </div>
                            ) : (
                                <TimerDisplay
                                    remainingSeconds={timerRemaining}
                                    timerState={timerState}
                                    isConnected={isConnected}
                                />
                            )}
                        </div>

                        {/* Previous ideas */}
                        <PreviousIdeas
                            ideas={previousIdeas}
                            authorName={previousAuthorName}
                            roundNumber={session.current_round}
                        />

                        {/* Idea input form - only for team members */}
                        {!isViewOnly && (
                            <IdeaInputForm
                                onSubmit={handleSubmitIdeas}
                                isDisabled={isInputDisabled}
                                isSubmitted={hasSubmitted}
                                submittedIdeas={submittedIdeaTexts}
                                isLoading={isSubmitting}
                                error={submitError}
                            />
                        )}
                    </div>

                    {/* Sidebar - 1 column */}
                    <div className="space-y-6">
                        {/* Session control panel for leaders and managers */}
                        {canControlSession && (
                            <SessionControlPanel
                                sessionId={sessionId}
                                status={session.status}
                                token={token}
                                onStatusChange={handleSessionStatusChange}
                            />
                        )}

                        {/* Team submission status */}
                        <TeamSubmissionStatus
                            submissions={teamSubmissions}
                            currentUserId={currentUserId}
                        />

                        {/* Session info card */}
                        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
                            <h3 className="text-sm font-semibold text-zinc-400 uppercase tracking-wider mb-4">
                                Session Rules
                            </h3>
                            <ul className="space-y-3 text-sm text-zinc-400">
                                <li className="flex items-start gap-2">
                                    <span className="text-emerald-400 mt-0.5">•</span>
                                    Submit exactly 3 ideas per round
                                </li>
                                <li className="flex items-start gap-2">
                                    <span className="text-emerald-400 mt-0.5">•</span>
                                    All ideas must be unique and non-empty
                                </li>
                                <li className="flex items-start gap-2">
                                    <span className="text-emerald-400 mt-0.5">•</span>
                                    Build upon previous round's ideas
                                </li>
                                <li className="flex items-start gap-2">
                                    <span className="text-emerald-400 mt-0.5">•</span>
                                    5 minutes per round
                                </li>
                                <li className="flex items-start gap-2">
                                    <span className="text-emerald-400 mt-0.5">•</span>
                                    {session.round_count} total rounds
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            {/* Connection status toast */}
            <ConnectionStatus
                isConnected={isConnected}
                isReconnecting={isReconnecting}
                onReconnect={requestSync}
            />
        </div>
    );
}
