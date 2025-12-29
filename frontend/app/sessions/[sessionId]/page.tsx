"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { SessionPageClient } from "@/components/session/SessionPageClient";
import { API_BASE_URL } from "@/lib/config";

export default function SessionPage() {
    const params = useParams();
    const router = useRouter();
    const sessionId = parseInt(params.sessionId as string, 10);

    const [isLoading, setIsLoading] = useState(true);
    const [token, setToken] = useState<string | null>(null);
    const [currentUserId, setCurrentUserId] = useState<number | null>(null);
    const [userRole, setUserRole] = useState<"member" | "leader" | "manager" | null>(null);

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

            // Fetch session state to determine user role
            fetchSessionState(storedToken, user.id);
        } catch (error) {
            console.error("Failed to parse user data", error);
            router.push("/login");
        }
    }, [sessionId, router]);

    const fetchSessionState = async (token: string, userId: number) => {
        try {
            const response = await fetch(`${API_BASE_URL}/sessions/${sessionId}/state`, {
                headers: {
                    Authorization: `Bearer ${token}`,
                },
            });

            if (response.status === 401 || response.status === 403) {
                // Unauthorized or forbidden - redirect to dashboard
                router.push("/dashboard");
                return;
            }

            if (!response.ok) {
                console.error("Failed to fetch session state");
                router.push("/dashboard");
                return;
            }

            const data = await response.json();

            // Determine user role from session state
            setUserRole(data.user_role || "member");
            setIsLoading(false);
        } catch (error) {
            console.error("Error fetching session state", error);
            router.push("/dashboard");
        }
    };

    if (isNaN(sessionId)) {
        router.push("/");
        return null;
    }

    if (isLoading || !token || !currentUserId || !userRole) {
        return (
            <div className="min-h-screen flex items-center justify-center">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
                    <p className="mt-4 text-gray-600">Loading session...</p>
                </div>
            </div>
        );
    }

    return (
        <SessionPageClient
            sessionId={sessionId}
            token={token}
            currentUserId={currentUserId}
            userRole={userRole}
        />
    );
}
