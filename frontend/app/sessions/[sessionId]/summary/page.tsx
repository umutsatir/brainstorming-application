"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { SessionSummaryClient } from "@/components/session/SessionSummaryClient";

export default function SessionSummaryPage() {
    const params = useParams();
    const router = useRouter();
    const sessionId = parseInt(params.sessionId as string, 10);

    const [isLoading, setIsLoading] = useState(true);
    const [token, setToken] = useState<string | null>(null);
    const [currentUserId, setCurrentUserId] = useState<number | null>(null);

    useEffect(() => {
        // Check authentication
        const storedToken = localStorage.getItem("token");
        if (!storedToken) {
            router.push("/login");
            return;
        }

        // Get user info from localStorage
        const userStr = localStorage.getItem("user");
        if (!userStr) {
            router.push("/login");
            return;
        }

        try {
            const user = JSON.parse(userStr);
            setToken(storedToken);
            setCurrentUserId(user.id);
            setIsLoading(false);
        } catch (error) {
            console.error("Failed to parse user data", error);
            router.push("/login");
        }
    }, [sessionId, router]);

    if (isNaN(sessionId)) {
        router.push("/");
        return null;
    }

    if (isLoading || !token || !currentUserId) {
        return (
            <div className="min-h-screen flex items-center justify-center">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
                    <p className="mt-4 text-gray-600">Loading summary...</p>
                </div>
            </div>
        );
    }

    return (
        <SessionSummaryClient
            sessionId={sessionId}
            token={token}
            currentUserId={currentUserId}
        />
    );
}
