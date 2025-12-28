import { User } from "./user";

export enum SessionStatus {
    PENDING = "PENDING",
    RUNNING = "RUNNING",
    PAUSED = "PAUSED",
    COMPLETED = "COMPLETED",
}

export enum TimerState {
    RUNNING = "RUNNING",
    PAUSED = "PAUSED",
    FINISHED = "FINISHED",
}

export interface Session {
    id: number;
    team_id: number;
    team_name: string;
    topic_id: number;
    topic_title: string;
    status: SessionStatus;
    current_round: number;
    round_count: number;
    created_at: string;
    updated_at: string;
}

export interface Round {
    id: number;
    session_id: number;
    round_number: number;
    start_time: string | null;
    end_time: string | null;
    timer_state: TimerState;
    created_at: string;
}

export interface Idea {
    id: number;
    session_id: number;
    round_id: number;
    round_number: number;
    team_id: number;
    author_id: number;
    author_name: string;
    text: string;
    passed_from_user_id: number | null;
    passed_from_user_name: string | null;
    created_at: string;
    updated_at: string;
}

export interface TeamMemberSubmissionStatus {
    user_id: number;
    user_name: string;
    submitted: boolean;
    submitted_at: string | null;
}

export interface SessionState {
    session: Session;
    current_round: Round;
    timer_remaining_seconds: number;
    previous_ideas: Idea[];
    my_ideas: Idea[];
    team_submissions: TeamMemberSubmissionStatus[];
    can_submit: boolean;
    is_round_locked: boolean;
}

// WebSocket message types
export enum WsMessageType {
    // Client -> Server
    JOIN_SESSION = "JOIN_SESSION",
    LEAVE_SESSION = "LEAVE_SESSION",
    SUBMIT_IDEAS = "SUBMIT_IDEAS",
    SYNC_REQUEST = "SYNC_REQUEST",

    // Server -> Client
    SESSION_STATE = "SESSION_STATE",
    TIMER_TICK = "TIMER_TICK",
    ROUND_START = "ROUND_START",
    ROUND_END = "ROUND_END",
    MEMBER_SUBMITTED = "MEMBER_SUBMITTED",
    SESSION_PAUSED = "SESSION_PAUSED",
    SESSION_RESUMED = "SESSION_RESUMED",
    SESSION_COMPLETED = "SESSION_COMPLETED",
    ERROR = "ERROR",
    SYNC_RESPONSE = "SYNC_RESPONSE",
}

export interface WsMessage {
    type: WsMessageType;
    payload: any;
    timestamp: string;
}

export interface SubmitIdeasPayload {
    session_id: number;
    round_number: number;
    ideas: string[];
}

export interface TimerTickPayload {
    remaining_seconds: number;
    timer_state: TimerState;
}

export interface RoundStartPayload {
    round: Round;
    previous_ideas: Idea[];
    timer_remaining_seconds: number;
}

export interface MemberSubmittedPayload {
    user_id: number;
    user_name: string;
    round_number: number;
}

export interface CreateIdeaRequest {
    session_id: number;
    round_number: number;
    ideas: string[];
}
