"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { 
    Download, 
    Calendar, 
    Users, 
    Sparkles, 
    ThumbsUp, 
    MessageSquare,
    LayoutGrid,
    List,
    ChevronRight,
    Loader2
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";

interface SessionSummaryClientProps {
    sessionId: number;
    token: string;
    currentUserId: number;
}

interface SessionData {
    id: number;
    team_id: number;
    team_name: string;
    topic_id: number | null;
    topic_title: string | null;
    status: string;
    current_round: number;
    round_count: number;
    created_at: string;
}

interface IdeaData {
    id: number;
    text: string;
    author_id: number;
    author_name: string;
    round_number: number;
    votes?: number;
    comments_count?: number;
    tags?: string[];
    status?: "viable" | "risky" | "selected" | null;
}

interface RoundIdeas {
    round_number: number;
    round_title: string;
    ideas: IdeaData[];
}

interface ParticipantData {
    id: number;
    name: string;
    avatar?: string;
}

export function SessionSummaryClient({ sessionId, token, currentUserId }: SessionSummaryClientProps) {
    const router = useRouter();
    
    const [session, setSession] = useState<SessionData | null>(null);
    const [ideasByRound, setIdeasByRound] = useState<RoundIdeas[]>([]);
    const [participants, setParticipants] = useState<ParticipantData[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [viewMode, setViewMode] = useState<"round" | "participant">("round");
    const [displayMode, setDisplayMode] = useState<"grid" | "list">("grid");

    // AI Summary (mock data for now - can be integrated with AI service later)
    const [aiSummary] = useState({
        text: "The team focused heavily on social media engagement, with a strong preference for short-form video content. A recurring theme was leveraging micro-influencers to boost organic reach without significantly increasing ad spend. There was also consensus on needing a consolidated dashboard for tracking metrics across platforms.",
        tags: ["#ViralMarketing", "#BudgetOptimization", "#Influencers", "#VideoContent"]
    });

    useEffect(() => {
        fetchSessionData();
    }, [sessionId]);

    const fetchSessionData = async () => {
        try {
            setLoading(true);
            setError(null);

            // Fetch session details
            const sessionResponse = await api.get(`/sessions/${sessionId}`);
            setSession(sessionResponse.data);

            // Fetch all ideas grouped by round
            const ideasResponse = await api.get(`/sessions/${sessionId}/ideas`);
            const data = ideasResponse.data;

            // Transform ideas data into rounds
            const rounds: RoundIdeas[] = [];
            const roundTitles = ["Divergent Thinking", "Refining Concepts", "Convergent Ideas", "Final Selection", "Action Items", "Implementation"];
            
            if (data.ideas_by_round) {
                Object.entries(data.ideas_by_round).forEach(([roundNum, participantIdeas]: [string, any]) => {
                    const roundNumber = parseInt(roundNum);
                    const allIdeas: IdeaData[] = [];
                    
                    participantIdeas.forEach((p: any) => {
                        p.ideas.forEach((idea: any) => {
                            allIdeas.push({
                                id: idea.id,
                                text: idea.text,
                                author_id: p.participant_id,
                                author_name: p.participant_name,
                                round_number: roundNumber,
                                votes: Math.floor(Math.random() * 20), // Mock votes
                                comments_count: Math.floor(Math.random() * 5), // Mock comments
                                tags: [],
                                status: null
                            });
                        });
                    });

                    rounds.push({
                        round_number: roundNumber,
                        round_title: roundTitles[roundNumber - 1] || `Round ${roundNumber}`,
                        ideas: allIdeas
                    });
                });
            }

            setIdeasByRound(rounds.sort((a, b) => a.round_number - b.round_number));

            // Fetch team members as participants
            if (sessionResponse.data.team_id) {
                const membersResponse = await api.get(`/teams/${sessionResponse.data.team_id}/members`);
                setParticipants(membersResponse.data.map((m: any) => ({
                    id: m.id,
                    name: m.full_name,
                    avatar: null
                })));
            }

        } catch (err: any) {
            console.error("Failed to fetch session data", err);
            setError(err.response?.data?.message || "Failed to load session summary");
        } finally {
            setLoading(false);
        }
    };

    const handleExportReport = () => {
        // TODO: Implement export functionality
        alert("Export report functionality coming soon!");
    };

    const getInitials = (name: string) => {
        return name?.split(" ").map(n => n[0]).join("").toUpperCase().substring(0, 2) || "??";
    };

    const getStatusColor = (status: string | null | undefined) => {
        switch (status) {
            case "viable": return "text-green-600 bg-green-50";
            case "risky": return "text-orange-600 bg-orange-50";
            case "selected": return "text-blue-600 bg-blue-50";
            default: return "";
        }
    };

    const formatDate = (dateString: string) => {
        const date = new Date(dateString);
        return date.toLocaleDateString("en-US", { 
            month: "long", 
            day: "numeric", 
            year: "numeric",
            hour: "numeric",
            minute: "2-digit",
            hour12: true
        });
    };

    const totalIdeas = ideasByRound.reduce((sum, round) => sum + round.ideas.length, 0);

    if (loading) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
            </div>
        );
    }

    if (error) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="text-center">
                    <p className="text-red-600 mb-4">{error}</p>
                    <Button onClick={() => router.back()}>Go Back</Button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Navigation */}
            <nav className="bg-white border-b border-gray-200 px-6 py-4">
                <div className="max-w-7xl mx-auto flex items-center justify-between">
                    <div className="flex items-center gap-2 text-sm text-gray-500">
                        <span className="hover:text-gray-700 cursor-pointer" onClick={() => router.push("/dashboard")}>
                            Dashboard
                        </span>
                        <ChevronRight className="h-4 w-4" />
                        <span className="hover:text-gray-700 cursor-pointer">Sessions</span>
                        <ChevronRight className="h-4 w-4" />
                        <span className="text-gray-900 font-medium">Reports</span>
                    </div>
                </div>
            </nav>

            {/* Main Content */}
            <div className="max-w-7xl mx-auto px-6 py-8">
                {/* Header */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 mb-6">
                    <div className="flex items-start justify-between mb-6">
                        <div>
                            <div className="text-sm text-gray-500 mb-2 flex items-center gap-2">
                                <span>Sessions</span>
                                <span>/</span>
                                <span>{session?.team_name}</span>
                                <span>/</span>
                                <span>{session?.topic_title || "Brainstorm"}</span>
                            </div>
                            <h1 className="text-3xl font-bold text-gray-900 mb-4">
                                {session?.topic_title || session?.team_name} Brainstorm
                            </h1>
                            <div className="flex items-center gap-6 text-sm text-gray-600">
                                <div className="flex items-center gap-2">
                                    <Calendar className="h-4 w-4" />
                                    <span>{session?.created_at ? formatDate(session.created_at) : "N/A"}</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <div className="flex -space-x-2">
                                        {participants.slice(0, 3).map((p, i) => (
                                            <div 
                                                key={p.id} 
                                                className="h-7 w-7 rounded-full bg-blue-100 border-2 border-white flex items-center justify-center text-xs font-medium text-blue-700"
                                            >
                                                {getInitials(p.name)}
                                            </div>
                                        ))}
                                        {participants.length > 3 && (
                                            <div className="h-7 w-7 rounded-full bg-gray-100 border-2 border-white flex items-center justify-center text-xs font-medium text-gray-600">
                                                +{participants.length - 3}
                                            </div>
                                        )}
                                    </div>
                                    <span>{participants.length} Participants</span>
                                </div>
                            </div>
                        </div>
                        <Button 
                            onClick={handleExportReport}
                            className="bg-blue-600 hover:bg-blue-700 text-white px-6"
                        >
                            <Download className="h-4 w-4 mr-2" />
                            Export Report
                        </Button>
                    </div>

                    {/* AI Summary */}
                    <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-6 border border-blue-100">
                        <div className="flex items-start gap-4">
                            <div className="flex-1">
                                <div className="flex items-center gap-2 text-blue-600 font-semibold mb-3">
                                    <Sparkles className="h-5 w-5" />
                                    AI Session Summary
                                </div>
                                <p className="text-gray-700 leading-relaxed mb-4">
                                    {aiSummary.text}
                                </p>
                                <div className="flex flex-wrap gap-2">
                                    {aiSummary.tags.map((tag, i) => (
                                        <span 
                                            key={i}
                                            className="px-3 py-1 bg-white rounded-full text-sm font-medium text-blue-600 border border-blue-200"
                                        >
                                            {tag}
                                        </span>
                                    ))}
                                </div>
                            </div>
                            <div className="text-blue-200">
                                <Sparkles className="h-16 w-16" />
                            </div>
                        </div>
                    </div>
                </div>

                {/* View Controls */}
                <div className="flex items-center justify-between mb-6">
                    <div className="flex items-center gap-2 bg-white rounded-lg p-1 border border-gray-200">
                        <button
                            onClick={() => setViewMode("round")}
                            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                                viewMode === "round" 
                                    ? "bg-gray-100 text-gray-900" 
                                    : "text-gray-500 hover:text-gray-700"
                            }`}
                        >
                            By Round
                        </button>
                        <button
                            onClick={() => setViewMode("participant")}
                            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                                viewMode === "participant" 
                                    ? "bg-gray-100 text-gray-900" 
                                    : "text-gray-500 hover:text-gray-700"
                            }`}
                        >
                            By Participant
                        </button>
                    </div>

                    <div className="flex items-center gap-4">
                        <span className="text-sm text-gray-500">View:</span>
                        <div className="flex items-center gap-1 bg-white rounded-lg p-1 border border-gray-200">
                            <button
                                onClick={() => setDisplayMode("grid")}
                                className={`p-2 rounded-md transition-colors ${
                                    displayMode === "grid" 
                                        ? "bg-gray-100 text-gray-900" 
                                        : "text-gray-400 hover:text-gray-600"
                                }`}
                            >
                                <LayoutGrid className="h-4 w-4" />
                            </button>
                            <button
                                onClick={() => setDisplayMode("list")}
                                className={`p-2 rounded-md transition-colors ${
                                    displayMode === "list" 
                                        ? "bg-gray-100 text-gray-900" 
                                        : "text-gray-400 hover:text-gray-600"
                                }`}
                            >
                                <List className="h-4 w-4" />
                            </button>
                        </div>
                    </div>
                </div>

                {/* Ideas by Round */}
                {viewMode === "round" && (
                    <div className="space-y-8">
                        {ideasByRound.map((round) => (
                            <div key={round.round_number}>
                                <div className="flex items-center justify-between mb-4">
                                    <div className="flex items-center gap-3">
                                        <span className="text-sm font-semibold text-blue-600 uppercase tracking-wide">
                                            Round {round.round_number}
                                        </span>
                                        <h2 className="text-xl font-bold text-gray-900">
                                            {round.round_title}
                                        </h2>
                                    </div>
                                    <span className="text-sm text-gray-500">
                                        {round.ideas.length} Ideas
                                    </span>
                                </div>

                                <div className={`grid gap-4 ${
                                    displayMode === "grid" 
                                        ? "grid-cols-1 md:grid-cols-2 lg:grid-cols-3" 
                                        : "grid-cols-1"
                                }`}>
                                    {round.ideas.map((idea) => (
                                        <IdeaCard 
                                            key={idea.id} 
                                            idea={idea} 
                                            getInitials={getInitials}
                                            getStatusColor={getStatusColor}
                                        />
                                    ))}
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Ideas by Participant */}
                {viewMode === "participant" && (
                    <div className="space-y-8">
                        {participants.map((participant) => {
                            const participantIdeas = ideasByRound.flatMap(round => 
                                round.ideas.filter(idea => idea.author_id === participant.id)
                            );

                            if (participantIdeas.length === 0) return null;

                            return (
                                <div key={participant.id}>
                                    <div className="flex items-center gap-3 mb-4">
                                        <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-medium">
                                            {getInitials(participant.name)}
                                        </div>
                                        <div>
                                            <h2 className="text-lg font-bold text-gray-900">
                                                {participant.name}
                                            </h2>
                                            <span className="text-sm text-gray-500">
                                                {participantIdeas.length} Ideas
                                            </span>
                                        </div>
                                    </div>

                                    <div className={`grid gap-4 ${
                                        displayMode === "grid" 
                                            ? "grid-cols-1 md:grid-cols-2 lg:grid-cols-3" 
                                            : "grid-cols-1"
                                    }`}>
                                        {participantIdeas.map((idea) => (
                                            <IdeaCard 
                                                key={idea.id} 
                                                idea={idea} 
                                                getInitials={getInitials}
                                                getStatusColor={getStatusColor}
                                                showRound
                                            />
                                        ))}
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}

                {/* Footer */}
                <div className="mt-12 text-center text-sm text-gray-400">
                    Generated by Brainstorm AI on {session?.created_at ? formatDate(session.created_at) : "N/A"}
                </div>
            </div>
        </div>
    );
}

// Idea Card Component
interface IdeaCardProps {
    idea: IdeaData;
    getInitials: (name: string) => string;
    getStatusColor: (status: string | null | undefined) => string;
    showRound?: boolean;
}

function IdeaCard({ idea, getInitials, getStatusColor, showRound }: IdeaCardProps) {
    return (
        <div className="bg-white rounded-xl p-5 border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex items-center gap-3 mb-3">
                <div className="h-8 w-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-600 text-sm font-medium">
                    {getInitials(idea.author_name)}
                </div>
                <span className="text-sm font-medium text-gray-700">{idea.author_name}</span>
                {idea.votes !== undefined && idea.votes > 0 && (
                    <div className="ml-auto flex items-center gap-1 text-blue-600">
                        <ThumbsUp className="h-4 w-4" />
                        <span className="text-sm font-medium">{idea.votes}</span>
                    </div>
                )}
            </div>

            <p className="text-gray-800 mb-4 leading-relaxed">{idea.text}</p>

            <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 text-sm text-gray-500">
                    {idea.comments_count !== undefined && idea.comments_count > 0 && (
                        <div className="flex items-center gap-1">
                            <MessageSquare className="h-4 w-4" />
                            <span>{idea.comments_count} comments</span>
                        </div>
                    )}
                    {showRound && (
                        <span className="text-blue-600 text-xs font-medium">
                            Round {idea.round_number}
                        </span>
                    )}
                </div>

                {idea.status && (
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(idea.status)}`}>
                        {idea.status.charAt(0).toUpperCase() + idea.status.slice(1)}
                    </span>
                )}
            </div>
        </div>
    );
}
