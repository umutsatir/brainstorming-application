import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { verifyToken } from "@/lib/jwt";
import db from "@/lib/db";
import { SessionPageClient } from "@/components/session/SessionPageClient";

interface SessionPageProps {
    params: Promise<{ sessionId: string }>;
}

export default async function SessionPage({ params }: SessionPageProps) {
    const { sessionId } = await params;
    const sessionIdNum = parseInt(sessionId, 10);

    if (isNaN(sessionIdNum)) {
        redirect("/");
    }

    // Get auth token from cookies or headers
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

    // Get session and check access
    const [sessions] = (await db.execute(
        `SELECT s.id, s.team_id, s.status
        FROM sessions s
        WHERE s.id = ?`,
        [sessionIdNum]
    )) as [any[], any];

    if (sessions.length === 0) {
        redirect("/");
    }

    const session = sessions[0];

    // Check team membership and determine role
    // Priority: leader > manager > member (leader can also submit ideas)
    const [leaderCheck] = (await db.execute(
        `SELECT 'leader' as role FROM teams WHERE id = ? AND leader_id = ?`,
        [session.team_id, currentUserId]
    )) as [any[], any];

    const [managerCheck] = (await db.execute(
        `SELECT 'manager' as role FROM events e 
        JOIN teams t ON e.id = t.event_id 
        WHERE t.id = ? AND e.owner_id = ?`,
        [session.team_id, currentUserId]
    )) as [any[], any];

    const [memberCheck] = (await db.execute(
        `SELECT 'member' as role FROM team_members WHERE team_id = ? AND user_id = ?`,
        [session.team_id, currentUserId]
    )) as [any[], any];

    let userRole: "member" | "leader" | "manager";

    // Leader takes priority (can submit ideas + control session)
    if (leaderCheck.length > 0) {
        userRole = "leader";
    } else if (managerCheck.length > 0) {
        userRole = "manager";
    } else if (memberCheck.length > 0) {
        userRole = "member";
    } else {
        // User doesn't have access
        redirect("/");
    }

    return (
        <SessionPageClient
            sessionId={sessionIdNum}
            token={token}
            currentUserId={currentUserId}
            userRole={userRole}
        />
    );
}

export const dynamic = "force-dynamic";
