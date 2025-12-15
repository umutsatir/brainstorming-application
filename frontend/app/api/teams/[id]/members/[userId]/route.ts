import { NextRequest, NextResponse } from "next/server";
import db from "@/lib/db";
import { getAuthUser } from "@/lib/auth";

// DELETE /api/teams/[id]/members/[userId] - Remove member from team
export async function DELETE(
    request: NextRequest,
    {
        params,
    }: {
        params:
            | Promise<{ id: string; userId: string }>
            | { id: string; userId: string };
    }
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
        const userId = parseInt(resolvedParams.userId);

        if (isNaN(teamId) || isNaN(userId)) {
            return NextResponse.json(
                { error: "Invalid team ID or user ID" },
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

        // Only EVENT_MANAGER (event owner) can remove members
        if (team.owner_id !== authUser.userId) {
            return NextResponse.json(
                { error: "Only event managers can remove team members" },
                { status: 403 }
            );
        }

        // Check if user is a member
        const [members] = (await db.execute(
            "SELECT id FROM team_members WHERE team_id = ? AND user_id = ?",
            [teamId, userId]
        )) as [any[], any];

        if (members.length === 0) {
            return NextResponse.json(
                { error: "User is not a member of this team" },
                { status: 404 }
            );
        }

        // Remove member
        await db.execute(
            "DELETE FROM team_members WHERE team_id = ? AND user_id = ?",
            [teamId, userId]
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
        const [remainingMembers] = (await db.execute(
            `SELECT tm.id, tm.user_id, tm.created_at,
              u.id as user_user_id, u.full_name as user_name, u.email as user_email
       FROM team_members tm
       LEFT JOIN users u ON tm.user_id = u.id
       WHERE tm.team_id = ?
       ORDER BY tm.created_at ASC`,
            [teamId]
        )) as [any[], any];

        return NextResponse.json({
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
                members: remainingMembers.map((m: any) => ({
                    id: m.id,
                    user_id: m.user_id,
                    user: {
                        id: m.user_user_id,
                        full_name: m.user_name,
                        email: m.user_email,
                    },
                    created_at: m.created_at,
                })),
                member_count: remainingMembers.length,
                created_at: updatedTeam.created_at,
                updated_at: updatedTeam.updated_at,
            },
            message: "Member removed successfully",
        });
    } catch (error: any) {
        console.error("Remove member error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}
