import { User } from "./user";

export interface Team {
  id: number;
  event_id: number;
  name: string;
  leader_id: number;
  created_at: Date;
  updated_at: Date;
}

export interface TeamWithDetails extends Team {
  leader: {
    id: number;
    full_name: string;
    email: string;
  };
  members: Array<{
    id: number;
    user_id: number;
    user: {
      id: number;
      full_name: string;
      email: string;
    };
    created_at: Date;
  }>;
  member_count: number;
}

export interface TeamCreate {
  name: string;
  leader_id: number;
  member_ids?: number[]; // Optional initial members
}

export interface TeamUpdate {
  name?: string;
  leader_id?: number;
}

export interface TeamRow {
  id: number;
  event_id: number;
  name: string;
  leader_id: number;
  created_at: Date;
  updated_at: Date;
}

export interface TeamMemberRow {
  id: number;
  team_id: number;
  user_id: number;
  created_at: Date;
}

