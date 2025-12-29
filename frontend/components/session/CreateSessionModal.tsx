"use client";

import { useState, useEffect } from "react";
import { X, Play, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";

interface Topic {
    id: number;
    title: string;
    description?: string;
}

interface CreateSessionModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: (sessionId: number) => void;
    teamId: number;
    teamName: string;
    eventId: number;
}

export function CreateSessionModal({
    isOpen,
    onClose,
    onSuccess,
    teamId,
    teamName,
    eventId,
}: CreateSessionModalProps) {
    const [topics, setTopics] = useState<Topic[]>([]);
    const [selectedTopicId, setSelectedTopicId] = useState<number | null>(null);
    const [roundCount, setRoundCount] = useState(6); // Default for 6-3-5
    const [loading, setLoading] = useState(false);
    const [loadingTopics, setLoadingTopics] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (isOpen && eventId) {
            fetchTopics();
        }
    }, [isOpen, eventId]);

    const fetchTopics = async () => {
        setLoadingTopics(true);
        try {
            const response = await api.get(`/events/${eventId}/topics`);
            setTopics(response.data);
            if (response.data.length > 0) {
                setSelectedTopicId(response.data[0].id);
            }
        } catch (err) {
            console.error("Failed to fetch topics", err);
            setError("Failed to load topics");
        } finally {
            setLoadingTopics(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        
        if (!selectedTopicId) {
            setError("Please select a topic");
            return;
        }

        setLoading(true);
        setError(null);

        try {
            // Create the session
            const response = await api.post(`/teams/${teamId}/sessions`, {
                teamId, // Required for backend validation
                topicId: selectedTopicId,
                roundCount: roundCount,
            });

            const sessionId = response.data.id;

            // Start the session immediately after creation
            await api.post(`/sessions/${sessionId}/start`);

            onSuccess(sessionId);
            onClose();
        } catch (err: any) {
            console.error("Failed to create/start session", err);
            setError(err.response?.data?.message || "Failed to create or start session");
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-md mx-4 overflow-hidden">
                {/* Header */}
                <div className="flex items-center justify-between p-4 border-b border-gray-100">
                    <div>
                        <h2 className="text-lg font-semibold text-gray-900">Start New Session</h2>
                        <p className="text-sm text-gray-500">Create a 6-3-5 brainstorming session for {teamName}</p>
                    </div>
                    <button
                        onClick={onClose}
                        className="text-gray-400 hover:text-gray-600 transition-colors"
                    >
                        <X className="h-5 w-5" />
                    </button>
                </div>

                {/* Form */}
                <form onSubmit={handleSubmit} className="p-4 space-y-4">
                    {error && (
                        <div className="bg-red-50 text-red-600 text-sm p-3 rounded-lg">
                            {error}
                        </div>
                    )}

                    {/* Topic Selection */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                            Select Topic
                        </label>
                        {loadingTopics ? (
                            <div className="flex items-center justify-center p-4">
                                <Loader2 className="h-5 w-5 animate-spin text-blue-600" />
                            </div>
                        ) : topics.length === 0 ? (
                            <div className="text-sm text-gray-500 p-4 bg-gray-50 rounded-lg text-center">
                                No topics available. Please create a topic first.
                            </div>
                        ) : (
                            <select
                                value={selectedTopicId || ""}
                                onChange={(e) => setSelectedTopicId(Number(e.target.value))}
                                className="w-full border border-gray-200 rounded-lg p-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                            >
                                {topics.map((topic) => (
                                    <option key={topic.id} value={topic.id}>
                                        {topic.title}
                                    </option>
                                ))}
                            </select>
                        )}
                    </div>

                    {/* Round Count */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                            Number of Rounds
                        </label>
                        <div className="flex items-center gap-3">
                            <input
                                type="range"
                                min="3"
                                max="10"
                                value={roundCount}
                                onChange={(e) => setRoundCount(Number(e.target.value))}
                                className="flex-1"
                            />
                            <span className="text-sm font-medium text-gray-900 w-8 text-center">
                                {roundCount}
                            </span>
                        </div>
                        <p className="text-xs text-gray-500 mt-1">
                            Standard 6-3-5 uses 6 rounds (6 participants × 3 ideas × 5 minutes)
                        </p>
                    </div>

                    {/* Info Box */}
                    <div className="bg-blue-50 p-3 rounded-lg">
                        <h4 className="text-sm font-medium text-blue-900 mb-1">How it works</h4>
                        <p className="text-xs text-blue-700">
                            Each team member writes 3 ideas per round. After each round, ideas are passed to the next member who builds upon them. This continues for {roundCount} rounds.
                        </p>
                    </div>

                    {/* Actions */}
                    <div className="flex gap-3 pt-2">
                        <Button
                            type="button"
                            variant="outline"
                            onClick={onClose}
                            className="flex-1"
                        >
                            Cancel
                        </Button>
                        <Button
                            type="submit"
                            disabled={loading || !selectedTopicId || topics.length === 0}
                            className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white"
                        >
                            {loading ? (
                                <>
                                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                                    Creating...
                                </>
                            ) : (
                                <>
                                    <Play className="h-4 w-4 mr-2" />
                                    Create Session
                                </>
                            )}
                        </Button>
                    </div>
                </form>
            </div>
        </div>
    );
}
