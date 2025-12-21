import { NextRequest, NextResponse } from "next/server";
import db from "@/lib/db";
import { getAuthUser } from "@/lib/auth";

// POST /api/events - Create a new event (for testing purposes)
export async function POST(request: NextRequest) {
  try {
    const authUser = await getAuthUser(request);

    if (!authUser) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Only EVENT_MANAGER can create events
    if (authUser.role !== "EVENT_MANAGER") {
      return NextResponse.json(
        { error: "Only event managers can create events" },
        { status: 403 }
      );
    }

    const body = await request.json();
    const { name, description, start_date, end_date } = body;

    if (!name) {
      return NextResponse.json(
        { error: "Name is required" },
        { status: 400 }
      );
    }

    // Create event
    const [result] = (await db.execute(
      "INSERT INTO events (name, description, start_date, end_date, owner_id) VALUES (?, ?, ?, ?, ?)",
      [name, description || null, start_date || null, end_date || null, authUser.userId]
    )) as [any, any];

    const eventId = result.insertId;

    // Get created event
    const [events] = (await db.execute(
      "SELECT id, name, description, start_date, end_date, owner_id, created_at, updated_at FROM events WHERE id = ?",
      [eventId]
    )) as [any[], any];

    const event = events[0];

    return NextResponse.json(
      {
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
      },
      { status: 201 }
    );
  } catch (error: any) {
    console.error("Create event error:", error);
    return NextResponse.json(
      { error: "Internal server error", message: error.message },
      { status: 500 }
    );
  }
}


