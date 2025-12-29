import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { verifyToken } from "@/lib/jwt";
import { SessionSummaryClient } from "@/components/session/SessionSummaryClient";

interface SessionSummaryPageProps {
    params: Promise<{ sessionId: string }>;
}

export default async function SessionSummaryPage({ params }: SessionSummaryPageProps) {
    const { sessionId } = await params;
    const sessionIdNum = parseInt(sessionId, 10);

    if (isNaN(sessionIdNum)) {
        redirect("/");
    }

    // Get auth token from cookies
    const cookieStore = await cookies();
    const token = cookieStore.get("token")?.value;

    if (!token) {
        redirect("/login");
    }

    // Verify token
    let payload;
    try {
        payload = verifyToken(token);
    } catch {
        redirect("/login");
    }

    const currentUserId = payload.userId;

    return (
        <SessionSummaryClient
            sessionId={sessionIdNum}
            token={token}
            currentUserId={currentUserId}
        />
    );
}

export const dynamic = "force-dynamic";
