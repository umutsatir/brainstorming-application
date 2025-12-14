import { NextRequest } from "next/server";
import { verifyToken } from "./jwt";

export async function getAuthUser(
    request: NextRequest
): Promise<{ userId: number; email: string; role: string } | null> {
    try {
        const authHeader = request.headers.get("authorization");

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return null;
        }

        const token = authHeader.substring(7);
        const payload = verifyToken(token);

        return {
            userId: payload.userId,
            email: payload.email,
            role: payload.role,
        };
    } catch (error) {
        return null;
    }
}
