"use client";

import { useEffect, useState } from "react";
import { GripHorizontal, Search, Loader2, Trash2, MoreVertical, Crown, Plus, UserPlus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { ConfirmationModal } from "@/components/ui/confirmation-modal";
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
  teamName?: string;
  userRole?: string | null;
  onTeamUpdated?: () => void;
  capacity?: number;
  eventId?: number | null;
}

export function ParticipantsList({ teamId, teamName, userRole, onTeamUpdated, capacity = 6, eventId }: ParticipantsListProps) {
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [allUsers, setAllUsers] = useState<Participant[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [showAllUsers, setShowAllUsers] = useState(false);
  const [addingUserId, setAddingUserId] = useState<number | null>(null);
  
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    variant: "danger" | "primary" | "warning";
    confirmText: string;
    onConfirm: () => Promise<void>;
  }>({
    isOpen: false,
    title: "",
    message: "",
    variant: "primary",
    confirmText: "Confirm",
    onConfirm: async () => {},
  });

  const closeConfirmModal = () => {
    setConfirmModal(prev => ({ ...prev, isOpen: false }));
  };

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
        params: {
          search: searchQuery,
          page: 0,
          size: 50,
          eventId: eventId || undefined // Pass eventId to filter out users already in teams
        }
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

      setConfirmModal({
        isOpen: true,
        title: "Remove Member",
        message: "Are you sure you want to remove this member from the team?",
        variant: "danger",
        confirmText: "Remove",
        onConfirm: async () => {
            try {
                await api.delete(`/teams/${teamId}/members/${userId}`);
                fetchParticipants();
                onTeamUpdated?.();
                closeConfirmModal();
            } catch (error) {
                console.error("Failed to remove member", error);
                alert("Failed to remove member");
            }
        }
      });
  };

  const handlePromoteToLeader = async (userId: number) => {
      if (!teamId) return;

      setConfirmModal({
        isOpen: true,
        title: "Promote to Leader",
        message: "Are you sure you want to promote this member to Team Leader? The current leader will become a regular team member.",
        variant: "warning",
        confirmText: "Promote",
        onConfirm: async () => {
            try {
                await api.put(`/teams/${teamId}/leader/${userId}`);
                fetchParticipants();
                onTeamUpdated?.();
                closeConfirmModal();
            } catch (error) {
                console.error("Failed to promote member", error);
                alert("Failed to promote member to Team Leader");
            }
        }
      });
  };

  const handleAddMember = async (userId: number) => {
      if (!teamId) return;
      
      if (participants.length >= capacity) {
        alert("Team is full. Cannot add more members.");
        return;
      }

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

  const isAuthorized = userRole === "EVENT_MANAGER" || userRole === "ROLE_EVENT_MANAGER" || userRole === "TEAM_LEADER" || userRole === "ROLE_TEAM_LEADER";
  const isEventManager = userRole === "EVENT_MANAGER" || userRole === "ROLE_EVENT_MANAGER";
  const isTeamFull = participants.length >= capacity;

  // Automatically switch back to "Current Members" view when team becomes full
  useEffect(() => {
    if (isTeamFull && showAllUsers) {
        setShowAllUsers(false);
    }
  }, [isTeamFull, showAllUsers]);

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
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 flex flex-col h-[calc(100vh-10rem)] overflow-hidden">
        {/* Header Section */}
        <div className="p-5 border-b border-gray-100 bg-white z-10 space-y-4">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="font-bold text-gray-900 text-lg truncate max-w-[200px]" title={teamName}>
                        {teamId ? (teamName || "Team Members") : "Select Team"}
                    </h2>
                    <p className="text-xs text-gray-500 mt-0.5">
                        {teamId 
                            ? `Manage members for this team` 
                            : "Select a team to view details"}
                    </p>
                </div>
                {teamId && (
                    <span className="text-xs font-bold text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full border border-blue-100">
                        {filteredParticipants.length} Active
                    </span>
                )}
            </div>

            {teamId && isAuthorized && (
                <div className="flex w-full border-b border-gray-100">
                    <button
                        className={`flex-1 pb-2 text-sm font-medium transition-all relative ${
                            !showAllUsers 
                                ? 'text-blue-600' 
                                : 'text-gray-500 hover:text-gray-700'
                        }`}
                        onClick={() => setShowAllUsers(false)}
                    >
                        Current Members
                        {!showAllUsers && (
                            <span className="absolute bottom-0 left-0 w-full h-0.5 bg-blue-600 rounded-t-full" />
                        )}
                    </button>
                    <button
                        className={`flex-1 pb-2 text-sm font-medium transition-all relative ${
                            showAllUsers 
                                ? 'text-blue-600' 
                                : isTeamFull 
                                    ? 'text-gray-300 cursor-not-allowed' 
                                    : 'text-gray-500 hover:text-gray-700'
                        }`}
                        onClick={() => !isTeamFull && setShowAllUsers(true)}
                        disabled={isTeamFull}
                        title={isTeamFull ? "Team is full" : "Add new member"}
                    >
                        Add New
                        {showAllUsers && (
                            <span className="absolute bottom-0 left-0 w-full h-0.5 bg-blue-600 rounded-t-full" />
                        )}
                    </button>
                </div>
            )}
            
            {teamId && (
                <div className="relative group">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 group-focus-within:text-blue-500 transition-colors" />
                    <input 
                        className="w-full pl-9 pr-4 py-2.5 text-sm bg-gray-50 border border-gray-200 rounded-lg focus:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                        placeholder={showAllUsers ? "Search users to add..." : "Search members by name..."}
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </div>
            )}
        </div>
        
        {/* List Content */}
        <div className="flex-1 overflow-y-auto p-3 space-y-2 bg-gray-50/30">
            {loading ? (
                <div className="flex flex-col items-center justify-center h-full text-gray-400 gap-2">
                    <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
                    <span className="text-sm">Loading members...</span>
                </div>
            ) : showAllUsers ? (
                // Show all users for adding to team
                filteredAllUsers.length > 0 ? (
                    filteredAllUsers.map((user) => (
                        <div key={user.id} className="flex items-center gap-3 p-3 bg-white border border-gray-100 hover:border-blue-200 hover:shadow-sm rounded-xl group transition-all duration-200">
                            <div className="h-10 w-10 rounded-full bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-100 flex items-center justify-center text-blue-600 font-bold text-sm shadow-sm">
                                {getInitials(getName(user))}
                            </div>
                            <div className="flex-1 min-w-0">
                                <div className="font-semibold text-sm text-gray-900 truncate">
                                    {getName(user)}
                                </div>
                                <div className="text-xs text-gray-500 truncate flex items-center gap-1">
                                    <span className="w-1.5 h-1.5 rounded-full bg-gray-300"></span>
                                    {user.email || user.role}
                                </div>
                            </div>
                            <Button
                                size="sm"
                                className="h-8 px-3 bg-white text-blue-600 border border-blue-200 hover:bg-blue-50 hover:border-blue-300 shadow-sm opacity-0 group-hover:opacity-100 transition-all translate-x-2 group-hover:translate-x-0"
                                onClick={() => handleAddMember(user.id)}
                                disabled={addingUserId === user.id}
                            >
                                {addingUserId === user.id ? (
                                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                                ) : (
                                    <>
                                        <Plus className="h-3.5 w-3.5 mr-1.5" /> Add
                                    </>
                                )}
                            </Button>
                        </div>
                    ))
                ) : (
                    <div className="flex flex-col items-center justify-center h-48 text-gray-400 bg-white rounded-xl border border-dashed border-gray-200 m-2">
                        <div className="h-12 w-12 bg-gray-50 rounded-full flex items-center justify-center mb-3">
                            <UserPlus className="h-6 w-6 text-gray-300" />
                        </div>
                        <span className="font-medium text-gray-900">No users found</span>
                        <span className="text-xs mt-1">Try a different search term</span>
                    </div>
                )
            ) : teamId ? (
                // Show team members
                filteredParticipants.length > 0 ? (
                    filteredParticipants.map((p) => (
                        <div key={p.id} className="flex items-center gap-3 p-3 bg-white border border-gray-100 hover:border-indigo-200 hover:shadow-sm rounded-xl group transition-all duration-200">
                            <div className={`h-10 w-10 rounded-full flex items-center justify-center font-bold text-sm shadow-sm border ${
                                p.is_team_leader 
                                    ? 'bg-amber-50 text-amber-600 border-amber-100' 
                                    : 'bg-gray-50 text-gray-600 border-gray-100'
                            }`}>
                                {p.is_team_leader ? <Crown className="h-5 w-5" /> : getInitials(getName(p))}
                            </div>
                            <div className="flex-1 min-w-0">
                                <div className="font-semibold text-sm text-gray-900 truncate flex items-center gap-1.5">
                                    {getName(p)}
                                    {p.is_team_leader && (
                                        <span className="text-[10px] font-bold bg-amber-100 text-amber-700 px-1.5 py-0.5 rounded border border-amber-200">LEADER</span>
                                    )}
                                </div>
                                <div className="text-xs text-gray-500 truncate flex items-center gap-1">
                                    <span className={`w-1.5 h-1.5 rounded-full ${p.is_team_leader ? 'bg-amber-400' : 'bg-green-400'}`}></span>
                                    {p.role}
                                </div>
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
                                                Promote to Leader
                                            </DropdownMenuItem>
                                        )}
                                        <DropdownMenuItem 
                                            onClick={() => handleRemoveMember(p.id)}
                                            className="cursor-pointer text-red-600 focus:text-red-600 focus:bg-red-50"
                                        >
                                            <Trash2 className="h-4 w-4 mr-2" />
                                            Remove Member
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
                    <div className="flex flex-col items-center justify-center h-48 text-gray-400 bg-white rounded-xl border border-dashed border-gray-200 m-2">
                        <div className="h-12 w-12 bg-gray-50 rounded-full flex items-center justify-center mb-3">
                            <UserPlus className="h-6 w-6 text-gray-300" />
                        </div>
                        <span className="font-medium text-gray-900">No members yet</span>
                        <span className="text-xs mt-1">Add members to start collaborating</span>
                    </div>
                )
            ) : (
                <div className="flex flex-col items-center justify-center h-full text-gray-400 p-8 text-center">
                    <div className="h-16 w-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                        <GripHorizontal className="h-8 w-8 text-gray-300" />
                    </div>
                    <h3 className="font-semibold text-gray-900">No Team Selected</h3>
                    <p className="text-sm mt-1 max-w-[200px]">Select a team from the list to view and manage its members.</p>
                </div>
            )}
        </div>
        
        <ConfirmationModal
            isOpen={confirmModal.isOpen}
            onClose={closeConfirmModal}
            onConfirm={confirmModal.onConfirm}
            title={confirmModal.title}
            message={confirmModal.message}
            variant={confirmModal.variant}
            confirmText={confirmModal.confirmText}
        />
     </div>
  );
}
