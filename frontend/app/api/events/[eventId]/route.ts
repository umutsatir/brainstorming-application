import { NextRequest, NextResponse } from "next/server";
import db from "@/lib/db";
import { getAuthUser } from "@/lib/auth";

// GET /api/events/[eventId] - Get a single event
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

        // Only EVENT_MANAGER can view events
        if (authUser.role !== "EVENT_MANAGER") {
            return NextResponse.json(
                { error: "Only event managers can view events" },
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

        // Get event
        const [events] = (await db.execute(
            "SELECT id, name, description, start_date, end_date, owner_id, created_at, updated_at FROM events WHERE id = ?",
            [eventId]
        )) as [any[], any];

        if (events.length === 0) {
            return NextResponse.json(
                { error: "Event not found" },
                { status: 404 }
            );
        }

        const event = events[0];

        return NextResponse.json({
            event: {
                id: event.id,
                name: event.name,
                description: event.description,
                start_date: event.start_date,
                end_date: event.end_date,
                owner_id: event.owner_id,
                created_at: event.created_at,
                updated_at: event.updated_at,
            },
        });
    } catch (error: any) {
        console.error("Get event error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}

// PATCH /api/events/[eventId] - Update event metadata
export async function PATCH(
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

        // Only EVENT_MANAGER can update events
        if (authUser.role !== "EVENT_MANAGER") {
            return NextResponse.json(
                { error: "Only event managers can update events" },
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

        // Check if event exists and user is the owner
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

        // Only the owner can update the event
        if (event.owner_id !== authUser.userId) {
            return NextResponse.json(
                { error: "You can only update events you own" },
                { status: 403 }
            );
        }

        const body = await request.json();
        const { name, description, start_date, end_date } = body;

        // Build update query dynamically based on provided fields
        const updates: string[] = [];
        const values: any[] = [];

        if (name !== undefined) {
            updates.push("name = ?");
            values.push(name);
        }
        if (description !== undefined) {
            updates.push("description = ?");
            values.push(description);
        }
        if (start_date !== undefined) {
            updates.push("start_date = ?");
            values.push(start_date);
        }
        if (end_date !== undefined) {
            updates.push("end_date = ?");
            values.push(end_date);
        }

        if (updates.length === 0) {
            return NextResponse.json(
                { error: "No fields to update" },
                { status: 400 }
            );
        }

        values.push(eventId);

        // Update event
        await db.execute(
            `UPDATE events SET ${updates.join(", ")} WHERE id = ?`,
            values
        );

        // Get updated event
        const [updatedEvents] = (await db.execute(
            "SELECT id, name, description, start_date, end_date, owner_id, created_at, updated_at FROM events WHERE id = ?",
            [eventId]
        )) as [any[], any];

        const updatedEvent = updatedEvents[0];

        return NextResponse.json({
            event: {
                id: updatedEvent.id,
                name: updatedEvent.name,
                description: updatedEvent.description,
                start_date: updatedEvent.start_date,
                end_date: updatedEvent.end_date,
                owner_id: updatedEvent.owner_id,
                created_at: updatedEvent.created_at,
                updated_at: updatedEvent.updated_at,
            },
        });
    } catch (error: any) {
        console.error("Update event error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}

// DELETE /api/events/[eventId] - Archive/soft-delete event
export async function DELETE(
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

        // Only EVENT_MANAGER can delete events
        if (authUser.role !== "EVENT_MANAGER") {
            return NextResponse.json(
                { error: "Only event managers can delete events" },
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

        // Check if event exists and user is the owner
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

        // Only the owner can delete the event
        if (event.owner_id !== authUser.userId) {
            return NextResponse.json(
                { error: "You can only delete events you own" },
                { status: 403 }
            );
        }

        // Note: For soft-delete, you might want to add a deleted_at column
        // For now, we'll do a hard delete. If you want soft-delete, uncomment below:
        // await db.execute(
        //   "UPDATE events SET deleted_at = NOW() WHERE id = ?",
        //   [eventId]
        // );

        // Hard delete (if no foreign key constraints prevent it)
        await db.execute("DELETE FROM events WHERE id = ?", [eventId]);

        return NextResponse.json(
            { message: "Event deleted successfully" },
            { status: 200 }
        );
    } catch (error: any) {
        console.error("Delete event error:", error);

        // Check if it's a foreign key constraint error
        if (error.code === "ER_ROW_IS_REFERENCED_2" || error.code === "23000") {
            return NextResponse.json(
                {
                    error: "Cannot delete event: it has associated teams, topics, or sessions",
                },
                { status: 409 }
            );
        }

        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}
