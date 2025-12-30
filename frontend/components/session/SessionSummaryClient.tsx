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
    Loader2,
    CornerUpLeft
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { jsPDF } from "jspdf";

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

    // AI Summary
    const [aiSummary, setAiSummary] = useState<{
        text: string;
        tags: string[];
    } | null>(null);
    const [isGeneratingSummary, setIsGeneratingSummary] = useState(false);

    useEffect(() => {
        fetchSessionData();
        fetchAiSummary();
    }, [sessionId]);

    const fetchAiSummary = async () => {
        try {
            const response = await api.get(`/ai/sessions/${sessionId}/summary`);
            if (response.data) {
                setAiSummary({
                    text: response.data.summary_text,
                    tags: response.data.key_themes || []
                });
            }
        } catch (error) {
            // Ignore 404 (not found) or other errors, just don't show summary
            console.log("No existing summary found or failed to fetch");
        }
    };

    const handleGenerateSummary = async () => {
        setIsGeneratingSummary(true);
        try {
            const response = await api.post(`/ai/sessions/${sessionId}/summary`, {});
            setAiSummary({
                text: response.data.summary_text,
                tags: response.data.key_themes || []
            });
        } catch (error: any) {
            console.error("Failed to generate summary", error);
            const errorMessage = error.response?.data?.message || "Failed to generate AI summary. Please try again later.";
            alert(errorMessage);
        } finally {
            setIsGeneratingSummary(false);
        }
    };

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

    const handleExportReport = async () => {
        if (!session) return;

        const doc = new jsPDF();
        
        // Load a font that supports Turkish characters (Roboto)
        try {
            const fontResponse = await fetch('https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.66/fonts/Roboto/Roboto-Regular.ttf');
            if (fontResponse.ok) {
                const fontBlob = await fontResponse.blob();
                const reader = new FileReader();
                await new Promise((resolve) => {
                    reader.onloadend = () => {
                        const base64data = reader.result as string;
                        const base64 = base64data.split(',')[1];
                        doc.addFileToVFS("Roboto-Regular.ttf", base64);
                        doc.addFont("Roboto-Regular.ttf", "Roboto", "normal");
                        doc.setFont("Roboto");
                        resolve(true);
                    };
                    reader.readAsDataURL(fontBlob);
                });
            }
        } catch (e) {
            console.warn("Could not load custom font, falling back to default", e);
        }

        const pageWidth = doc.internal.pageSize.width;
        const pageHeight = doc.internal.pageSize.height;
        const margin = 20;
        const contentWidth = pageWidth - (margin * 2);
        let y = 20;

        const checkPageBreak = (heightNeeded: number) => {
            if (y + heightNeeded > pageHeight - margin) {
                doc.addPage();
                y = margin;
                return true;
            }
            return false;
        };

        // --- Header ---
        doc.setFontSize(22);
        doc.setTextColor(37, 99, 235); // Blue-600
        const title = `${session.topic_title || session.team_name} Report`;
        const titleLines = doc.splitTextToSize(title, contentWidth);
        doc.text(titleLines, margin, y);
        y += (titleLines.length * 10) + 5;

        doc.setFontSize(10);
        doc.setTextColor(107, 114, 128); // Gray-500
        doc.text(`Date: ${new Date().toLocaleDateString()}`, margin, y);
        y += 5;
        doc.text(`Team: ${session.team_name}`, margin, y);
        y += 5;
        doc.text(`Participants: ${participants.map(p => p.name).join(", ")}`, margin, y);
        y += 15;

        // --- AI Summary ---
        if (aiSummary) {
            checkPageBreak(60); // Estimate height
            
            // Background Box
            doc.setFillColor(239, 246, 255); // Blue-50
            doc.setDrawColor(219, 234, 254); // Blue-100
            
            // Calculate text height
            doc.setFontSize(11);
            const summaryTextLines = doc.splitTextToSize(aiSummary.text, contentWidth - 10);
            const summaryHeight = (summaryTextLines.length * 5) + 25 + (aiSummary.tags.length > 0 ? 15 : 0);
            
            doc.roundedRect(margin, y, contentWidth, summaryHeight, 3, 3, 'FD');
            
            let boxY = y + 10;
            
            // Title
            doc.setFontSize(12);
            doc.setTextColor(37, 99, 235); // Blue-600
            doc.text("AI Executive Summary", margin + 5, boxY);
            boxY += 8;
            
            // Text
            doc.setFontSize(10);
            doc.setTextColor(55, 65, 81); // Gray-700
            doc.text(summaryTextLines, margin + 5, boxY);
            boxY += (summaryTextLines.length * 5) + 5;
            
            // Tags
            if (aiSummary.tags.length > 0) {
                doc.setFontSize(9);
                doc.setTextColor(75, 85, 99); // Gray-600
                doc.text("Key Themes: " + aiSummary.tags.join(", "), margin + 5, boxY);
            }
            
            y += summaryHeight + 10;
        }

        // --- Ideas ---
        doc.setFontSize(16);
        doc.setTextColor(17, 24, 39); // Gray-900
        doc.text("Brainstorming Details", margin, y);
        y += 10;

        ideasByRound.forEach(round => {
            checkPageBreak(20);
            
            // Round Header
            doc.setFillColor(243, 244, 246); // Gray-100
            doc.rect(margin, y, contentWidth, 8, 'F');
            doc.setFontSize(11);
            doc.setTextColor(31, 41, 55); // Gray-800
            doc.text(`Round ${round.round_number}: ${round.round_title}`, margin + 2, y + 5.5);
            y += 12;

            // Ideas Cards
            round.ideas.forEach(idea => {
                doc.setFontSize(10);
                const ideaTextLines = doc.splitTextToSize(idea.text, contentWidth - 20); // Padding
                const cardHeight = (ideaTextLines.length * 5) + 20;
                
                checkPageBreak(cardHeight + 5);

                // Card Box
                doc.setDrawColor(229, 231, 235); // Gray-200
                doc.setFillColor(255, 255, 255); // White
                doc.roundedRect(margin, y, contentWidth, cardHeight, 2, 2, 'FD');

                // Avatar Circle (Simulation)
                doc.setFillColor(239, 246, 255); // Blue-50
                doc.circle(margin + 8, y + 8, 4, 'F');
                doc.setFontSize(7);
                doc.setTextColor(37, 99, 235); // Blue-600
                const initials = getInitials(idea.author_name);
                doc.text(initials, margin + 6.5, y + 9);

                // Author Name
                doc.setFontSize(9);
                doc.setTextColor(17, 24, 39); // Gray-900
                // Bold simulation by printing twice with slight offset or just color
                doc.text(idea.author_name, margin + 15, y + 9);

                // Idea Text
                doc.setFontSize(10);
                doc.setTextColor(55, 65, 81); // Gray-700
                doc.text(ideaTextLines, margin + 5, y + 18);

                // Status Badge (if exists)
                if (idea.status) {
                    const statusText = idea.status.toUpperCase();
                    doc.setFontSize(7);
                    const badgeWidth = doc.getTextWidth(statusText) + 4;
                    
                    // Badge Color
                    if (idea.status === 'selected') doc.setFillColor(219, 234, 254); // Blue-100
                    else if (idea.status === 'risky') doc.setFillColor(255, 237, 213); // Orange-100
                    else doc.setFillColor(243, 244, 246); // Gray-100

                    doc.roundedRect(margin + contentWidth - badgeWidth - 5, y + 5, badgeWidth, 5, 1, 1, 'F');
                    doc.setTextColor(31, 41, 55);
                    doc.text(statusText, margin + contentWidth - badgeWidth - 3, y + 8.5);
                }

                y += cardHeight + 5;
            });
            
            y += 5; // Space between rounds
        });

        // Footer
        const pageCount = doc.getNumberOfPages();
        for (let i = 1; i <= pageCount; i++) {
            doc.setPage(i);
            doc.setFontSize(8);
            doc.setTextColor(156, 163, 175); // Gray-400
            doc.text(`Page ${i} of ${pageCount}`, pageWidth - margin, pageHeight - 10, { align: "right" });
            doc.text(`Generated by Brainstorm AI`, margin, pageHeight - 10);
        }

        doc.save(`${session.topic_title?.replace(/\s+/g, '_') || 'session'}_report.pdf`);
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
            <div id="report-content" className="max-w-7xl mx-auto px-6 py-8">
                {/* Header */}
                <div className="relative bg-white rounded-2xl shadow-sm border border-gray-100 p-8 mb-6">
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
                            onClick={() => router.push("/")}
                            className="h-9 bg-gradient-to-r from-blue-50 to-indigo-50 hover:from-blue-100 hover:to-indigo-100 text-blue-700 border border-blue-200 px-6"
                        >
                            Return to Home
                            <CornerUpLeft className="h-4 w-4 ml-2" />
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
                                
                                {aiSummary ? (
                                    <>
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
                                    </>
                                ) : (
                                    <div className="flex flex-col items-start gap-3">
                                        <p className="text-gray-600 text-sm">
                                            Generate an AI-powered summary of this session to identify key themes and insights.
                                        </p>
                                        <Button 
                                            onClick={handleGenerateSummary}
                                            disabled={isGeneratingSummary}
                                            className="bg-white text-blue-600 border border-blue-200 hover:bg-blue-50"
                                            size="sm"
                                        >
                                            {isGeneratingSummary ? (
                                                <>
                                                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                                                    Generating...
                                                </>
                                            ) : (
                                                <>
                                                    <Sparkles className="h-4 w-4 mr-2" />
                                                    Generate Summary
                                                </>
                                            )}
                                        </Button>
                                    </div>
                                )}
                            </div>
                            <div className="text-blue-200 hidden sm:block">
                                <Sparkles className="h-16 w-16" />
                            </div>
                        </div>
                    </div>
                </div>

                {/* View Controls */}
                <div className="flex items-center justify-between mb-6">
                    <div className="flex items-center gap-3">
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

                        <Button
                            id="export-button"
                            onClick={handleExportReport}
                            className="h-[42px] w-[42px] p-0 bg-white border border-gray-200 text-gray-600 hover:text-blue-600 hover:border-blue-200 hover:bg-blue-50 rounded-lg shadow-sm"
                            title="Export Report"
                        >
                            <Download className="h-5 w-5" />
                        </Button>
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
                                    {Object.values(round.ideas.reduce((acc, idea) => {
                                        if (!acc[idea.author_id]) {
                                            acc[idea.author_id] = {
                                                author: {
                                                    id: idea.author_id,
                                                    name: idea.author_name
                                                },
                                                ideas: []
                                            };
                                        }
                                        acc[idea.author_id].ideas.push(idea);
                                        return acc;
                                    }, {} as Record<number, { author: { id: number, name: string }, ideas: typeof round.ideas }>)).map((userGroup) => (
                                        <GroupedIdeasCard 
                                            key={userGroup.author.id}
                                            title={userGroup.author.name}
                                            ideas={userGroup.ideas}
                                            initials={getInitials(userGroup.author.name)}
                                            getStatusColor={getStatusColor}
                                            variant="user"
                                        />
                                    ))}
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Ideas by Participant */}
                {viewMode === "participant" && (
                    <div className="space-y-16">
                        {participants.map((participant) => {
                            // Group ideas by round for this participant
                            const userRounds = ideasByRound.map(round => ({
                                ...round,
                                ideas: round.ideas.filter(idea => idea.author_id === participant.id)
                            })).filter(round => round.ideas.length > 0);

                            if (userRounds.length === 0) return null;

                            const totalIdeas = userRounds.reduce((acc, r) => acc + r.ideas.length, 0);

                            return (
                                <div key={participant.id}>
                                    <div className="flex items-center gap-4 mb-6 border-b border-gray-100 pb-4">
                                        <div className="h-14 w-14 rounded-full bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center text-white font-bold text-xl shadow-md">
                                            {getInitials(participant.name)}
                                        </div>
                                        <div>
                                            <h2 className="text-2xl font-bold text-gray-900">
                                                {participant.name}
                                            </h2>
                                            <div className="flex items-center gap-2 text-sm text-gray-500 mt-1">
                                                <span className="bg-blue-50 text-blue-700 px-2 py-0.5 rounded-full font-medium">
                                                    {totalIdeas} Ideas
                                                </span>
                                                <span>•</span>
                                                <span>{userRounds.length} Rounds Active</span>
                                            </div>
                                        </div>
                                    </div>

                                    <div className={`grid gap-6 ${
                                        displayMode === "grid" 
                                            ? "grid-cols-1 md:grid-cols-2 lg:grid-cols-3" 
                                            : "grid-cols-1"
                                    }`}>
                                        {userRounds.map(round => (
                                            <GroupedIdeasCard 
                                                key={round.round_number}
                                                title={round.round_title || `Round ${round.round_number}`}
                                                ideas={round.ideas}
                                                initials={`R${round.round_number}`}
                                                getStatusColor={getStatusColor}
                                                variant="round"
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
        <div className="group bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_2px_8px_rgba(0,0,0,0.04)] hover:shadow-[0_8px_24px_rgba(0,0,0,0.08)] transition-all duration-300">
            <div className="flex items-center gap-3 mb-4">
                <div className="h-10 w-10 rounded-full bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-100 flex items-center justify-center text-blue-600 text-sm font-bold shadow-sm">
                    {getInitials(idea.author_name)}
                </div>
                <div>
                    <h3 className="text-sm font-bold text-gray-900">{idea.author_name}</h3>
                    {showRound && (
                        <span className="text-xs font-medium text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full mt-0.5 inline-block">
                            Round {idea.round_number}
                        </span>
                    )}
                </div>
            </div>

            <p className="text-gray-700 leading-relaxed mb-4">{idea.text}</p>

            <div className="flex items-center justify-end">
                {idea.status && (
                    <span className={`px-2.5 py-1 rounded-md text-xs font-semibold tracking-wide uppercase ${getStatusColor(idea.status)} bg-opacity-10 border border-opacity-20`}>
                        {idea.status}
                    </span>
                )}
            </div>
        </div>
    );
}

interface GroupedIdeasCardProps {
    title: string;
    ideas: IdeaData[];
    initials: string;
    getStatusColor: (status: string | null | undefined) => string;
    variant?: 'user' | 'round';
}

function GroupedIdeasCard({ title, ideas, initials, getStatusColor, variant = 'user' }: GroupedIdeasCardProps) {
    const isRound = variant === 'round';
    
    return (
        <div className="group bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_2px_8px_rgba(0,0,0,0.04)] hover:shadow-[0_8px_24px_rgba(0,0,0,0.08)] transition-all duration-300 h-full flex flex-col">
            <div className="flex items-center gap-3 mb-6">
                <div className={`h-10 w-10 rounded-full flex items-center justify-center text-sm font-bold shadow-sm border ${
                    isRound 
                        ? "bg-gradient-to-br from-amber-50 to-orange-50 border-amber-100 text-amber-600" 
                        : "bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-100 text-blue-600"
                }`}>
                    {initials}
                </div>
                <div>
                    <h3 className="text-sm font-bold text-gray-900">{title}</h3>
                    <span className="text-xs text-gray-500 font-medium">{ideas.length} ideas contributed</span>
                </div>
            </div>

            <div className="space-y-3 flex-1">
                {ideas.map((idea) => (
                    <div key={idea.id} className={`group/idea relative pl-4 border-l-2 transition-colors py-1 ${
                        isRound 
                            ? "border-gray-100 hover:border-amber-400" 
                            : "border-gray-100 hover:border-blue-400"
                    }`}>
                        <p className="text-gray-700 text-sm leading-relaxed mb-2">{idea.text}</p>
                        
                        <div className="flex items-center justify-between min-h-[20px]">
                             <div className="flex items-center gap-2">
                                {/* No extra badges needed here as context is clear */}
                             </div>
                            {idea.status && (
                                <span className={`px-2 py-0.5 rounded-md text-[10px] font-semibold tracking-wide uppercase ${getStatusColor(idea.status)} bg-opacity-10 border border-opacity-20`}>
                                    {idea.status}
                                </span>
                            )}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
