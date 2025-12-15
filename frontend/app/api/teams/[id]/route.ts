import { NextRequest, NextResponse } from "next/server";
import db from "@/lib/db";
import { getAuthUser } from "@/lib/auth";
import { TeamUpdate, TeamRow } from "@/types/team";

// GET /api/teams/[id] - Get team details with members
export async function GET(
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

        // Get team with leader info
        const [teams] = (await db.execute(
            `SELECT t.id, t.event_id, t.name, t.leader_id, t.created_at, t.updated_at,
              u.id as leader_user_id, u.full_name as leader_name, u.email as leader_email,
              e.id as event_id_check, e.owner_id
       FROM teams t
       LEFT JOIN users u ON t.leader_id = u.id
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

        // Check access: Event Manager (owner) or Team Leader or Team Member
        const isEventManager = team.owner_id === authUser.userId;
        const isTeamLeader = team.leader_id === authUser.userId;

        // Check if user is a member
        const [memberCheck] = (await db.execute(
            "SELECT id FROM team_members WHERE team_id = ? AND user_id = ?",
            [teamId, authUser.userId]
        )) as [any[], any];

        const isTeamMember = memberCheck.length > 0;

        if (!isEventManager && !isTeamLeader && !isTeamMember) {
            return NextResponse.json(
                { error: "You don't have access to this team" },
                { status: 403 }
            );
        }

        // Get members
        const [members] = (await db.execute(
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
                id: team.id,
                event_id: team.event_id,
                name: team.name,
                leader_id: team.leader_id,
                leader: {
                    id: team.leader_user_id,
                    full_name: team.leader_name,
                    email: team.leader_email,
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
                created_at: team.created_at,
                updated_at: team.updated_at,
            },
        });
    } catch (error: any) {
        console.error("Get team error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}

// PATCH /api/teams/[id] - Update team
export async function PATCH(
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
            `SELECT t.id, t.event_id, t.name, t.leader_id,
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

        // Only EVENT_MANAGER (event owner) can update teams
        if (team.owner_id !== authUser.userId) {
            return NextResponse.json(
                { error: "Only event managers can update teams" },
                { status: 403 }
            );
        }

        const body: TeamUpdate = await request.json();
        const { name, leader_id } = body;

        // Build update query
        const updates: string[] = [];
        const values: any[] = [];

        if (name !== undefined) {
            updates.push("name = ?");
            values.push(name);
        }

        if (leader_id !== undefined) {
            // Verify new leader exists
            const [leaders] = (await db.execute(
                "SELECT id FROM users WHERE id = ?",
                [leader_id]
            )) as [any[], any];

            if (leaders.length === 0) {
                return NextResponse.json(
                    { error: "Leader not found" },
                    { status: 404 }
                );
            }

            updates.push("leader_id = ?");
            values.push(leader_id);
        }

        if (updates.length === 0) {
            return NextResponse.json(
                { error: "No fields to update" },
                { status: 400 }
            );
        }

        updates.push("updated_at = CURRENT_TIMESTAMP");
        values.push(teamId);

        // Update team
        await db.execute(
            `UPDATE teams SET ${updates.join(", ")} WHERE id = ?`,
            values
        );

        // Get updated team
        const [updatedTeams] = (await db.execute(
            `SELECT t.id, t.event_id, t.name, t.leader_id, t.created_at, t.updated_at,
              u.id as leader_user_id, u.full_name as leader_name, u.email as leader_email
       FROM teams t
       LEFT JOIN users u ON t.leader_id = u.id
       WHERE t.id = ?`,
            [teamId]
        )) as [any[], any];

        const updatedTeam = updatedTeams[0];

        // Get members
        const [members] = (await db.execute(
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
        });
    } catch (error: any) {
        console.error("Update team error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}

// DELETE /api/teams/[id] - Delete team
export async function DELETE(
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
            `SELECT t.id, t.event_id,
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

        // Only EVENT_MANAGER (event owner) can delete teams
        if (team.owner_id !== authUser.userId) {
            return NextResponse.json(
                { error: "Only event managers can delete teams" },
                { status: 403 }
            );
        }

        // Delete team members first (foreign key constraint)
        await db.execute("DELETE FROM team_members WHERE team_id = ?", [
            teamId,
        ]);

        // Delete team
        await db.execute("DELETE FROM teams WHERE id = ?", [teamId]);

        return NextResponse.json(
            { message: "Team deleted successfully" },
            { status: 200 }
        );
    } catch (error: any) {
        console.error("Delete team error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}
