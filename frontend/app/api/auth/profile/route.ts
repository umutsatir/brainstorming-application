import { NextRequest, NextResponse } from "next/server";
import db from "@/lib/db";
import { getAuthUser } from "@/lib/auth";
import { UserUpdate, UserRow } from "@/types/user";

// GET /api/auth/profile - Get current user profile
export async function GET(request: NextRequest) {
    try {
        const authUser = await getAuthUser(request);

        if (!authUser) {
            return NextResponse.json(
                { error: "Unauthorized" },
                { status: 401 }
            );
        }

        // Get user from database
        const [users] = (await db.execute(
            "SELECT id, full_name, email, phone, role, status, created_at, updated_at FROM users WHERE id = ?",
            [authUser.userId]
        )) as [UserRow[], any];

        const user = users.length > 0 ? users[0] : null;

        if (!user) {
            return NextResponse.json(
                { error: "User not found" },
                { status: 404 }
            );
        }

        return NextResponse.json({
            user: {
                id: user.id,
                full_name: user.full_name,
                email: user.email,
                phone: user.phone,
                role: user.role,
                status: user.status,
                created_at: user.created_at.toISOString(),
                updated_at: user.updated_at.toISOString(),
            },
        });
    } catch (error: any) {
        console.error("Get profile error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}

// PUT /api/auth/profile - Update current user profile
export async function PUT(request: NextRequest) {
    try {
        const authUser = await getAuthUser(request);

        if (!authUser) {
            return NextResponse.json(
                { error: "Unauthorized" },
                { status: 401 }
            );
        }

        const body: UserUpdate = await request.json();
        const { full_name, phone } = body;

        // Build update query dynamically
        const updates: string[] = [];
        const values: any[] = [];

        if (full_name !== undefined) {
            updates.push("full_name = ?");
            values.push(full_name);
        }

        if (phone !== undefined) {
            updates.push("phone = ?");
            values.push(phone);
        }

        if (updates.length === 0) {
            return NextResponse.json(
                { error: "No fields to update" },
                { status: 400 }
            );
        }

        // Add updated_at
        updates.push("updated_at = CURRENT_TIMESTAMP");
        values.push(authUser.userId);

        // Update user
        await db.execute(
            `UPDATE users SET ${updates.join(", ")} WHERE id = ?`,
            values
        );

        // Get updated user
        const [users] = (await db.execute(
            "SELECT id, full_name, email, phone, role, status, created_at, updated_at FROM users WHERE id = ?",
            [authUser.userId]
        )) as [UserRow[], any];

        const user = users.length > 0 ? users[0] : null;

        if (!user) {
            return NextResponse.json(
                { error: "User not found" },
                { status: 404 }
            );
        }

        return NextResponse.json({
            user: {
                id: user.id,
                full_name: user.full_name,
                email: user.email,
                phone: user.phone,
                role: user.role,
                status: user.status,
                created_at: user.created_at.toISOString(),
                updated_at: user.updated_at.toISOString(),
            },
        });
    } catch (error: any) {
        console.error("Update profile error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}
