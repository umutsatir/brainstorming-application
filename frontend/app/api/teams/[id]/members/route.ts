import { NextRequest, NextResponse } from "next/server";
import db from "@/lib/db";
import { getAuthUser } from "@/lib/auth";

// POST /api/teams/[id]/members - Add member to team
export async function POST(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> | { id: string } }
) {
    try {
        const authUser = await getAuthUser(request);

        if (!authUser) {
            return NextResponse.json(
                { error: "Unauthorized" },
                { status: 401 }
            );
        }

        const resolvedParams = await Promise.resolve(params);
        const teamId = parseInt(resolvedParams.id);
        if (isNaN(teamId)) {
            return NextResponse.json(
                { error: "Invalid team ID" },
                { status: 400 }
            );
        }

        // Get team and event info
        const [teams] = (await db.execute(
            `SELECT t.id, t.event_id, t.leader_id,
              e.owner_id
       FROM teams t
       LEFT JOIN events e ON t.event_id = e.id
       WHERE t.id = ?`,
            [teamId]
        )) as [any[], any];

        if (teams.length === 0) {
            return NextResponse.json(
                { error: "Team not found" },
                { status: 404 }
            );
        }

        const team = teams[0];

        // Only EVENT_MANAGER (event owner) can add members
        if (team.owner_id !== authUser.userId) {
            return NextResponse.json(
                { error: "Only event managers can add team members" },
                { status: 403 }
            );
        }

        const body = await request.json();
        const { user_id } = body;

        if (!user_id) {
            return NextResponse.json(
                { error: "user_id is required" },
                { status: 400 }
            );
        }

        // Verify user exists
        const [users] = (await db.execute("SELECT id FROM users WHERE id = ?", [
            user_id,
        ])) as [any[], any];

        if (users.length === 0) {
            return NextResponse.json(
                { error: "User not found" },
                { status: 404 }
            );
        }

        // Check if user is already the leader
        if (team.leader_id === user_id) {
            return NextResponse.json(
                { error: "User is already the team leader" },
                { status: 400 }
            );
        }

        // Check if user is already a member
        const [existingMembers] = (await db.execute(
            "SELECT id FROM team_members WHERE team_id = ? AND user_id = ?",
            [teamId, user_id]
        )) as [any[], any];

        if (existingMembers.length > 0) {
            return NextResponse.json(
                { error: "User is already a member of this team" },
                { status: 409 }
            );
        }

        // Check team size (max 5 members for 6-3-5: 1 leader + 5 members = 6 total)
        const [memberCount] = (await db.execute(
            "SELECT COUNT(*) as count FROM team_members WHERE team_id = ?",
            [teamId]
        )) as [any[], any];

        if (memberCount[0].count >= 5) {
            return NextResponse.json(
                { error: "Team is full (maximum 5 members allowed)" },
                { status: 400 }
            );
        }

        // Add member
        await db.execute(
            "INSERT INTO team_members (team_id, user_id) VALUES (?, ?)",
            [teamId, user_id]
        );

        // Get updated team with members
        const [updatedTeams] = (await db.execute(
            `SELECT t.id, t.event_id, t.name, t.leader_id, t.created_at, t.updated_at,
              u.id as leader_user_id, u.full_name as leader_name, u.email as leader_email
       FROM teams t
       LEFT JOIN users u ON t.leader_id = u.id
       WHERE t.id = ?`,
            [teamId]
        )) as [any[], any];

        const updatedTeam = updatedTeams[0];

        // Get all members
        const [members] = (await db.execute(
            `SELECT tm.id, tm.user_id, tm.created_at,
              u.id as user_user_id, u.full_name as user_name, u.email as user_email
       FROM team_members tm
       LEFT JOIN users u ON tm.user_id = u.id
       WHERE tm.team_id = ?
       ORDER BY tm.created_at ASC`,
            [teamId]
        )) as [any[], any];

        return NextResponse.json(
            {
                team: {
                    id: updatedTeam.id,
                    event_id: updatedTeam.event_id,
                    name: updatedTeam.name,
                    leader_id: updatedTeam.leader_id,
                    leader: {
                        id: updatedTeam.leader_user_id,
                        full_name: updatedTeam.leader_name,
                        email: updatedTeam.leader_email,
                    },
                    members: members.map((m: any) => ({
                        id: m.id,
                        user_id: m.user_id,
                        user: {
                            id: m.user_user_id,
                            full_name: m.user_name,
                            email: m.user_email,
                        },
                        created_at: m.created_at,
                    })),
                    member_count: members.length,
                    created_at: updatedTeam.created_at,
                    updated_at: updatedTeam.updated_at,
                },
            },
            { status: 201 }
        );
    } catch (error: any) {
        console.error("Add member error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}
