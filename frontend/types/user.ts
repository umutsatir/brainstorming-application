export enum UserRole {
    EVENT_MANAGER = "EVENT_MANAGER",
    TEAM_LEADER = "TEAM_LEADER",
    TEAM_MEMBER = "TEAM_MEMBER",
}

export enum UserStatus {
    ACTIVE = "ACTIVE",
    INACTIVE = "INACTIVE",
    INVITED = "INVITED",
}

export interface User {
    id: number;
    full_name: string;
    email: string;
    phone: string | null;
    role: UserRole;
    status: UserStatus;
    created_at: Date;
    updated_at: Date;
}

export interface UserCreate {
    full_name: string;
    email: string;
    password: string;
    phone?: string;
    role?: UserRole;
}

export interface UserUpdate {
    full_name?: string;
    phone?: string;
}

export interface UserRow {
    id: number;
    full_name: string;
    email: string;
    password_hash?: string;
    phone: string | null;
    role: UserRole;
    status: UserStatus;
    created_at: Date;
    updated_at: Date;
}

export interface LoginRequest {
    email: string;
    password: string;
}

export interface AuthResponse {
    user: Omit<User, "created_at" | "updated_at"> & {
        created_at: string;
        updated_at: string;
    };
    token: string;
}
