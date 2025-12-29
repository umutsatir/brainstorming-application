"use client";

import { useEffect, useState } from "react";
import { GripHorizontal, Search, Loader2, Trash2, MoreVertical, Crown, Plus, UserPlus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

interface Participant {
  id: number;
  full_name?: string;
  fullName?: string;
  role: string;
  status: string;
  is_team_leader?: boolean;
  email?: string;
}

interface ParticipantsListProps {
  teamId: number | null;
  userRole?: string | null;
  onTeamUpdated?: () => void;
}

export function ParticipantsList({ teamId, userRole, onTeamUpdated }: ParticipantsListProps) {
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [allUsers, setAllUsers] = useState<Participant[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [showAllUsers, setShowAllUsers] = useState(false);
  const [addingUserId, setAddingUserId] = useState<number | null>(null);

  const fetchParticipants = async () => {
    if (!teamId) {
      setParticipants([]);
      setLoading(false);
      return;
    }
    
    setLoading(true);
    try {
      const response = await api.get(`/teams/${teamId}/members`);
      setParticipants(response.data);
    } catch (error) {
      console.error("Failed to fetch participants", error);
    } finally {
      setLoading(false);
    }
  };

  const fetchAllUsers = async () => {
    try {
      const response = await api.get(`/users`, {
        params: { search: searchQuery, page: 0, size: 50 }
      });
      // Handle paginated response
      const users = response.data.content || response.data;
      setAllUsers(users);
    } catch (error) {
      console.error("Failed to fetch users", error);
    }
  };

  useEffect(() => {
    fetchParticipants();
  }, [teamId]);

  useEffect(() => {
    if (showAllUsers) {
      fetchAllUsers();
    }
  }, [showAllUsers, searchQuery]);

  const handleRemoveMember = async (userId: number, e?: React.MouseEvent) => {
      e?.stopPropagation();
      if (!teamId) return;

      if (!confirm("Are you sure you want to remove this member from the team?")) return;

      try {
          await api.delete(`/teams/${teamId}/members/${userId}`);
          fetchParticipants();
          onTeamUpdated?.();
      } catch (error) {
          console.error("Failed to remove member", error);
          alert("Failed to remove member");
      }
  };

  const handlePromoteToLeader = async (userId: number) => {
      if (!teamId) return;

      if (!confirm("Are you sure you want to promote this member to Team Leader? The current leader will become a regular team member.")) return;

      try {
          await api.put(`/teams/${teamId}/leader/${userId}`);
          fetchParticipants();
          onTeamUpdated?.();
      } catch (error) {
          console.error("Failed to promote member", error);
          alert("Failed to promote member to Team Leader");
      }
  };

  const handleAddMember = async (userId: number) => {
      if (!teamId) return;
      
      setAddingUserId(userId);
      try {
          await api.post(`/teams/${teamId}/members`, [userId]);
          fetchParticipants();
          onTeamUpdated?.();
          // Remove added user from the displayed list
          setAllUsers(prev => prev.filter(u => u.id !== userId));
      } catch (error) {
          console.error("Failed to add member", error);
          alert("Failed to add member to team");
      } finally {
          setAddingUserId(null);
      }
  };

  const isEventManager = userRole === "EVENT_MANAGER" || userRole === "ROLE_EVENT_MANAGER";

  const filteredParticipants = participants.filter(p => {
    const name = p.full_name || p.fullName || "";
    return name.toLowerCase().includes(searchQuery.toLowerCase()) ||
           p.role?.toLowerCase().includes(searchQuery.toLowerCase());
  });

  // Filter out users that are already in the team
  const teamMemberIds = new Set(participants.map(p => p.id));
  const filteredAllUsers = allUsers.filter(u => !teamMemberIds.has(u.id));

  const listTitle = showAllUsers ? "Add Members" : (teamId ? "Team Members" : "Select a Team");

  const getInitials = (name: string) => {
    return name?.split(" ").map(n => n[0]).join("").toUpperCase().substring(0, 2) || "??";
  };

  const getName = (p: Participant) => p.full_name || p.fullName || "Unknown";

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden flex flex-col h-[calc(100vh-12rem)]">
        <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-white sticky top-0 z-10">
            <h2 className="font-semibold text-gray-900">{listTitle}</h2>
            <div className="flex items-center gap-2">
                {teamId && isEventManager && (
                    <Button
                        variant={showAllUsers ? "secondary" : "ghost"}
                        size="sm"
                        onClick={() => setShowAllUsers(!showAllUsers)}
                        className="text-xs"
                    >
                        <UserPlus className="h-4 w-4 mr-1" />
                        {showAllUsers ? "View Team" : "Add"}
                    </Button>
                )}
                <span className="text-xs font-medium text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
                    {showAllUsers ? filteredAllUsers.length : filteredParticipants.length}
                </span>
            </div>
        </div>
        <div className="p-4 border-b border-gray-100">
             <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input 
                    className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                    placeholder={showAllUsers ? "Search users by name or email..." : "Search by name or role..."}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                />
             </div>
        </div>
        
        <div className="flex-1 overflow-y-auto p-2 space-y-1">
            {loading ? (
                <div className="flex items-center justify-center h-full text-gray-400">
                    <Loader2 className="h-6 w-6 animate-spin" />
                </div>
            ) : showAllUsers ? (
                // Show all users for adding to team
                filteredAllUsers.length > 0 ? (
                    filteredAllUsers.map((user) => (
                        <div key={user.id} className="flex items-center gap-3 p-3 hover:bg-gray-50 rounded-lg group transition-colors">
                            <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-medium text-sm">
                                {getInitials(getName(user))}
                            </div>
                            <div className="flex-1 min-w-0">
                                <div className="font-medium text-sm text-gray-900 truncate">
                                    {getName(user)}
                                </div>
                                <div className="text-xs text-gray-500 truncate">{user.email || user.role}</div>
                            </div>
                            <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8 text-green-600 hover:text-green-700 hover:bg-green-50 opacity-0 group-hover:opacity-100 transition-all"
                                onClick={() => handleAddMember(user.id)}
                                disabled={addingUserId === user.id}
                                title="Add to team"
                            >
                                {addingUserId === user.id ? (
                                    <Loader2 className="h-4 w-4 animate-spin" />
                                ) : (
                                    <Plus className="h-4 w-4" />
                                )}
                            </Button>
                        </div>
                    ))
                ) : (
                    <div className="flex flex-col items-center justify-center h-32 text-sm text-gray-400">
                        <UserPlus className="h-8 w-8 mb-2 opacity-50" />
                        <span>No users available to add</span>
                    </div>
                )
            ) : teamId ? (
                // Show team members
                filteredParticipants.length > 0 ? (
                    filteredParticipants.map((p) => (
                        <div key={p.id} className="flex items-center gap-3 p-3 hover:bg-gray-50 rounded-lg cursor-grab group transition-colors">
                            <GripHorizontal className="text-gray-300 h-4 w-4 opacity-0 group-hover:opacity-100" />
                            <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-medium text-sm">
                                {getInitials(getName(p))}
                            </div>
                            <div className="flex-1 min-w-0">
                                <div className="font-medium text-sm text-gray-900 truncate flex items-center gap-1">
                                    {getName(p)}
                                    {p.is_team_leader && (
                                        <Crown className="h-3 w-3 text-yellow-500" />
                                    )}
                                </div>
                                <div className="text-xs text-gray-500 truncate">{p.role}</div>
                            </div>
                            
                            {isEventManager ? (
                                <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            className="h-8 w-8 text-gray-400 hover:text-gray-600 opacity-0 group-hover:opacity-100 transition-all"
                                            onClick={(e) => e.stopPropagation()}
                                        >
                                            <MoreVertical className="h-4 w-4" />
                                        </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end" className="w-48">
                                        {!p.is_team_leader && (
                                            <DropdownMenuItem 
                                                onClick={() => handlePromoteToLeader(p.id)}
                                                className="cursor-pointer"
                                            >
                                                <Crown className="h-4 w-4 mr-2 text-yellow-500" />
                                                Promote to Team Leader
                                            </DropdownMenuItem>
                                        )}
                                        <DropdownMenuItem 
                                            onClick={() => handleRemoveMember(p.id)}
                                            className="cursor-pointer text-red-600 focus:text-red-600 focus:bg-red-50"
                                        >
                                            <Trash2 className="h-4 w-4 mr-2" />
                                            Remove from Team
                                        </DropdownMenuItem>
                                    </DropdownMenuContent>
                                </DropdownMenu>
                            ) : (
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-8 w-8 text-gray-400 hover:text-red-600 hover:bg-red-50 opacity-0 group-hover:opacity-100 transition-all"
                                    onClick={(e) => handleRemoveMember(p.id, e)}
                                    title="Remove from team"
                                >
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            )}
                        </div>
                    ))
                ) : (
                    <div className="flex items-center justify-center h-32 text-sm text-gray-400">
                        No team members found
                    </div>
                )
            ) : (
                <div className="flex flex-col items-center justify-center h-32 text-sm text-gray-400">
                    <span>Select a team to view members</span>
                </div>
            )}
        </div>
     </div>
  );
}
