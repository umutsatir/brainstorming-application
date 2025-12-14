import { NextRequest, NextResponse } from "next/server";
import bcrypt from "bcrypt";
import db from "@/lib/db";
import { generateToken } from "@/lib/jwt";
import { LoginRequest, UserRow } from "@/types/user";

export async function POST(request: NextRequest) {
    try {
        const body: LoginRequest = await request.json();
        const { email, password } = body;

        // Validation
        if (!email || !password) {
            return NextResponse.json(
                { error: "Email and password are required" },
                { status: 400 }
            );
        }

        // Find user
        const [users] = (await db.execute(
            "SELECT id, full_name, email, password_hash, phone, role, status, created_at, updated_at FROM users WHERE email = ?",
            [email]
        )) as [UserRow[], any];

        const user = users.length > 0 ? users[0] : null;

        if (!user || !user.password_hash) {
            return NextResponse.json(
                { error: "Invalid email or password" },
                { status: 401 }
            );
        }

        // Check password
        const passwordMatch = await bcrypt.compare(
            password,
            user.password_hash
        );

        if (!passwordMatch) {
            return NextResponse.json(
                { error: "Invalid email or password" },
                { status: 401 }
            );
        }

        // Check if user is active
        if (user.status !== "ACTIVE") {
            return NextResponse.json(
                { error: "Account is not active" },
                { status: 403 }
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
        console.error("Login error:", error);
        return NextResponse.json(
            { error: "Internal server error", message: error.message },
            { status: 500 }
        );
    }
}
