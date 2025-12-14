import { NextRequest, NextResponse } from "next/server";
import bcrypt from "bcrypt";
import db from "@/lib/db";
import { generateToken } from "@/lib/jwt";
import { UserCreate, UserRole, UserRow } from "@/types/user";

export async function POST(request: NextRequest) {
    try {
        const body: UserCreate = await request.json();
        const { full_name, email, password, phone, role } = body;

        // Validation
        if (!full_name || !email || !password) {
            return NextResponse.json(
                { error: "Full name, email, and password are required" },
                { status: 400 }
            );
        }

        // Check if user already exists
        const [existingUsers] = await db.execute(
            "SELECT id FROM users WHERE email = ?",
            [email]
        );

        if (Array.isArray(existingUsers) && existingUsers.length > 0) {
            return NextResponse.json(
                { error: "User with this email already exists" },
                { status: 409 }
            );
        }

        // Hash password
        const passwordHash = await bcrypt.hash(password, 10);

        // Insert user
        const [result] = await db.execute(
            `INSERT INTO users (full_name, email, password_hash, phone, role, status) 
       VALUES (?, ?, ?, ?, ?, 'ACTIVE')`,
            [
                full_name,
                email,
                passwordHash,
                phone || null,
                role || UserRole.TEAM_MEMBER,
            ]
        );

        const insertResult = result as any;
        const userId = insertResult.insertId;

        // Get created user
        const [users] = (await db.execute(
            "SELECT id, full_name, email, phone, role, status, created_at, updated_at FROM users WHERE id = ?",
            [userId]
        )) as [UserRow[], any];

        const user = users.length > 0 ? users[0] : null;

        if (!user) {
            return NextResponse.json(
                { error: "Failed to create user" },
                { status: 500 }
            );
        }

        // Generate token
        const token = generateToken({
            userId: user.id,
            email: user.email,
            role: user.role,
        });

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
            token,
        });
    } catch (error: any) {
        console.error("Registration error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}
