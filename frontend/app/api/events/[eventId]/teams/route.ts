import { NextRequest, NextResponse } from "next/server";
import db from "@/lib/db";
import { getAuthUser } from "@/lib/auth";
import { TeamCreate, TeamRow, TeamMemberRow } from "@/types/team";

// POST /api/events/[eventId]/teams - Create a new team
export async function POST(
    request: NextRequest,
    { params }: { params: Promise<{ eventId: string }> | { eventId: string } }
) {
    try {
        const authUser = await getAuthUser(request);

        if (!authUser) {
            return NextResponse.json(
                { error: "Unauthorized" },
                { status: 401 }
            );
        }

        // Only EVENT_MANAGER can create teams
        if (authUser.role !== "EVENT_MANAGER") {
            return NextResponse.json(
                { error: "Only event managers can create teams" },
                { status: 403 }
            );
        }

        const resolvedParams = await Promise.resolve(params);
        const eventId = parseInt(resolvedParams.eventId);
        if (isNaN(eventId)) {
            return NextResponse.json(
                { error: "Invalid event ID" },
                { status: 400 }
            );
        }

        // Verify event exists and user is the owner
        const [events] = (await db.execute(
            "SELECT id, owner_id FROM events WHERE id = ?",
            [eventId]
        )) as [any[], any];

        if (events.length === 0) {
            return NextResponse.json(
                { error: "Event not found" },
                { status: 404 }
            );
        }

        const event = events[0];
        if (event.owner_id !== authUser.userId) {
            return NextResponse.json(
                { error: "You are not the owner of this event" },
                { status: 403 }
            );
        }

        const body: TeamCreate = await request.json();
        const { name, leader_id, member_ids } = body;

        // Validation
        if (!name || !leader_id) {
            return NextResponse.json(
                { error: "Name and leader_id are required" },
                { status: 400 }
            );
        }

        // Verify leader exists
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

        // Create team
        const [result] = (await db.execute(
            "INSERT INTO teams (event_id, name, leader_id) VALUES (?, ?, ?)",
            [eventId, name, leader_id]
        )) as [any, any];

        const teamId = result.insertId;

        // Add members if provided
        if (member_ids && member_ids.length > 0) {
            // Verify all members exist
            const placeholders = member_ids.map(() => "?").join(",");
            const [members] = (await db.execute(
                `SELECT id FROM users WHERE id IN (${placeholders})`,
                member_ids
            )) as [any[], any];

            if (members.length !== member_ids.length) {
                // Rollback team creation
                await db.execute("DELETE FROM teams WHERE id = ?", [teamId]);
                return NextResponse.json(
                    { error: "One or more members not found" },
                    { status: 404 }
                );
            }

            // Add members (max 5 members for 6-3-5 method: 1 leader + 5 members = 6 total)
            if (member_ids.length > 5) {
                await db.execute("DELETE FROM teams WHERE id = ?", [teamId]);
                return NextResponse.json(
                    {
                        error: "Maximum 5 members allowed (1 leader + 5 members = 6 total)",
                    },
                    { status: 400 }
                );
            }

            for (const memberId of member_ids) {
                // Don't add leader as member
                if (memberId !== leader_id) {
                    await db.execute(
                        "INSERT INTO team_members (team_id, user_id) VALUES (?, ?)",
                        [teamId, memberId]
                    );
                }
            }
        }

        // Get created team with details
        const [teams] = (await db.execute(
            `SELECT t.id, t.event_id, t.name, t.leader_id, t.created_at, t.updated_at,
              u.id as leader_user_id, u.full_name as leader_name, u.email as leader_email
       FROM teams t
       LEFT JOIN users u ON t.leader_id = u.id
       WHERE t.id = ?`,
            [teamId]
        )) as [any[], any];

        const team = teams[0];

        // Get members
        const [members] = (await db.execute(
            `SELECT tm.id, tm.user_id, tm.created_at,
              u.id as user_user_id, u.full_name as user_name, u.email as user_email
       FROM team_members tm
       LEFT JOIN users u ON tm.user_id = u.id
       WHERE tm.team_id = ?`,
            [teamId]
        )) as [any[], any];

        return NextResponse.json(
            {
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
            },
            { status: 201 }
        );
    } catch (error: any) {
        console.error("Create team error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}

// GET /api/events/[eventId]/teams - List all teams for an event
export async function GET(
    request: NextRequest,
    { params }: { params: Promise<{ eventId: string }> | { eventId: string } }
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
        const eventId = parseInt(resolvedParams.eventId);
        if (isNaN(eventId)) {
            return NextResponse.json(
                { error: "Invalid event ID" },
                { status: 400 }
            );
        }

        // Get teams with leader info
        const [teams] = (await db.execute(
            `SELECT t.id, t.event_id, t.name, t.leader_id, t.created_at, t.updated_at,
              u.id as leader_user_id, u.full_name as leader_name, u.email as leader_email
       FROM teams t
       LEFT JOIN users u ON t.leader_id = u.id
       WHERE t.event_id = ?
       ORDER BY t.created_at DESC`,
            [eventId]
        )) as [any[], any];

        // Get member counts for each team
        const teamIds = teams.map((t: any) => t.id);
        const memberCounts: Record<number, number> = {};

        if (teamIds.length > 0) {
            const placeholders = teamIds.map(() => "?").join(",");
            const [memberCountsResult] = (await db.execute(
                `SELECT team_id, COUNT(*) as count
         FROM team_members
         WHERE team_id IN (${placeholders})
         GROUP BY team_id`,
                teamIds
            )) as [any[], any];

            memberCountsResult.forEach((row: any) => {
                memberCounts[row.team_id] = row.count;
            });
        }

        const teamsWithDetails = teams.map((team: any) => ({
            id: team.id,
            event_id: team.event_id,
            name: team.name,
            leader_id: team.leader_id,
            leader: {
                id: team.leader_user_id,
                full_name: team.leader_name,
                email: team.leader_email,
            },
            member_count: memberCounts[team.id] || 0,
            created_at: team.created_at,
            updated_at: team.updated_at,
        }));

        return NextResponse.json({ teams: teamsWithDetails });
    } catch (error: any) {
        console.error("Get teams error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}
