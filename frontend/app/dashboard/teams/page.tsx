"use client";

import { useState, useEffect } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { Plus, GripHorizontal, Search, SlidersHorizontal, LayoutGrid, Lock, MoreHorizontal, Users, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { ParticipantsList } from "@/components/teams/ParticipantsList";
import { TeamCard } from "@/components/teams/TeamCard";
import { CreateTeamModal } from "@/components/teams/CreateTeamModal";
import { DeleteConfirmationModal } from "@/components/teams/DeleteConfirmationModal";
import { StartSessionModal } from "@/components/teams/StartSessionModal";

interface Team {
  id: number;
  name: string;
  member_count: number;
  leader_name: string;
  focus: string;
  capacity: number;
}

export default function TeamsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const eventId = searchParams.get("eventId");

  /* State */
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(false); // Start false, wait for eventId
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [editTeam, setEditTeam] = useState<Team | undefined>(undefined);
  const [selectedTeamId, setSelectedTeamId] = useState<number | null>(null);
  
  // Delete Modal State
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [teamToDelete, setTeamToDelete] = useState<number | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  // Session Start Modal State
  const [startSessionModalOpen, setStartSessionModalOpen] = useState(false);
  const [sessionTeamId, setSessionTeamId] = useState<number | null>(null);

  const fetchTeams = async () => {
    if (!eventId) return;
    
    setLoading(true);
    try {
      const response = await api.get(`/events/${eventId}/teams`);
      setTeams(response.data);
    } catch (error) {
      console.error("Failed to fetch teams", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (eventId) {
        fetchTeams();
    }
  }, [eventId]);

  const [userRole, setUserRole] = useState<string | null>(null);

  useEffect(() => {
    // Get user role from localStorage
    const userStr = localStorage.getItem("user");
    if (userStr) {
        try {
            const user = JSON.parse(userStr);
            setUserRole(user.role || null);
        } catch (e) {
            console.error("Failed to parse user", e);
        }
    }
  }, []);

  const canDelete = userRole === "EVENT_MANAGER" || userRole === "ROLE_EVENT_MANAGER" || userRole === "TEAM_LEADER" || userRole === "ROLE_TEAM_LEADER";

  const handleTeamClick = (id: number) => {
      if (selectedTeamId === id) {
          setSelectedTeamId(null); // Toggle off
      } else {
          setSelectedTeamId(id);
      }
  };

  const handleEditClick = (team: Team) => {
      setEditTeam(team);
      setIsCreateModalOpen(true);
  };

  const handleCreateClick = () => {
      setEditTeam(undefined);
      setIsCreateModalOpen(true);
  };

  const confirmDelete = (id: number) => {
      setTeamToDelete(id);
      setDeleteModalOpen(true);
  };

  const handleDeleteTeam = async () => {
      if (!teamToDelete) return;
      
      setDeleteLoading(true);
      try {
          await api.delete(`/teams/${teamToDelete}`);
          
          // If selected team is deleted, deselect it
          if (selectedTeamId === teamToDelete) {
              setSelectedTeamId(null);
          }
          
          setDeleteModalOpen(false);
          setTeamToDelete(null);
          fetchTeams(); // Refresh list
      } catch (error) {
          console.error("Failed to delete team", error);
          // Handle error (toast?)
      } finally {
          setDeleteLoading(false);
      }
  };

  const handleStartSession = (teamId: number) => {
      if (!teamId) {
        console.error("handleStartSession called with null/undefined teamId");
        return;
      }
      setSessionTeamId(teamId);
      setStartSessionModalOpen(true);
  };

  const handleSessionStarted = (sessionId: number) => {
      router.push(`/sessions/${sessionId}`);
  };

  return (
    <div className="flex flex-col gap-6">
        {/* Breadcrumb / Header */}
        <div className="flex flex-col gap-1">
            <div className="text-sm text-gray-500">Dashboard / Events / Event #{eventId || "Unknown"}</div>
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold text-gray-900">Team Management</h1>
                <div className="flex items-center gap-3">
                    <Button 
                        className="bg-blue-600 hover:bg-blue-700 text-white shadow-md shadow-blue-500/20 transition-all hover:shadow-lg hover:translate-y-[-1px]"
                        onClick={handleCreateClick}
                        disabled={!eventId}
                    >
                        <Plus className="mr-2 h-4 w-4" />
                        Create New Team
                    </Button>
                </div>
            </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            {!eventId ? (
                <div className="col-span-12 flex flex-col items-center justify-center bg-white rounded-xl border border-gray-200 p-12 text-center">
                    <div className="h-16 w-16 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mb-4">
                        <Users className="h-8 w-8" />
                    </div>
                    <h2 className="text-xl font-bold text-gray-900">No Event Selected</h2>
                    <p className="text-gray-500 max-w-md mt-2">Please select an event from the Events page to view and manage its teams.</p>
                    <Button 
                        className="mt-6" 
                        onClick={() => router.push('/dashboard/events')}
                    >
                        Go to Events
                    </Button>
                </div>
            ) : (
                <>
                    {/* Left Column: Participants */}
                    <div className="lg:col-span-4 xl:col-span-3 flex flex-col gap-4">
                         <ParticipantsList 
                             teamId={selectedTeamId} 
                             teamName={teams.find(t => t.id === selectedTeamId)?.name}
                             capacity={teams.find(t => t.id === selectedTeamId)?.capacity}
                             userRole={userRole}
                             onTeamUpdated={fetchTeams}
                         />
                    </div>

                    {/* Right Column: Teams Grid */}
                    <div className="lg:col-span-8 xl:col-span-9 flex flex-col gap-6">
                        <div className="flex items-center justify-between">
                            <h2 className="text-xl font-bold text-gray-900">Active Teams</h2>
                            <div className="flex items-center gap-2">
                                <Button variant="ghost" size="icon">
                                     <SlidersHorizontal className="h-5 w-5 text-gray-500" />
                                </Button>
                                <Button variant="ghost" size="icon">
                                     <LayoutGrid className="h-5 w-5 text-gray-500" />
                                </Button>
                            </div>
                        </div>

                        {loading ? (
                            <div className="flex items-center justify-center h-64">
                                <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
                            </div>
                        ) : (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                {teams.map((team) => (
                                    <TeamCard 
                                        key={team.id} 
                                        team={team} 
                                        isSelected={selectedTeamId === team.id}
                                        onClick={() => handleTeamClick(team.id)}
                                        onDelete={() => confirmDelete(team.id)}
                                        onEdit={() => handleEditClick(team)}
                                        onStartSession={handleStartSession}
                                        canDelete={canDelete}
                                    />
                                ))}

                                {/* Add Team Card */}
                                <div 
                                    className="border-2 border-dashed border-gray-200 rounded-xl p-5 flex flex-col items-center justify-center gap-2 h-full min-h-[200px] hover:border-blue-400 hover:bg-blue-50/50 transition-all cursor-pointer group"
                                    onClick={handleCreateClick}
                                >
                                    <div className="h-12 w-12 rounded-full bg-gray-50 group-hover:bg-blue-100 flex items-center justify-center text-gray-400 group-hover:text-blue-600 transition-colors">
                                        <Plus className="h-6 w-6" />
                                    </div>
                                    <span className="font-medium text-gray-500 group-hover:text-blue-600">Add Another Team</span>
                                </div>
                            </div>
                        )}
                    </div>
                </>
            )}
        </div>

        <CreateTeamModal 
            isOpen={isCreateModalOpen} 
            onClose={() => setIsCreateModalOpen(false)}
            onSuccess={fetchTeams}
            eventId={Number(eventId)}
            initialData={editTeam}
        />
        
        <DeleteConfirmationModal 
            isOpen={deleteModalOpen}
            onClose={() => setDeleteModalOpen(false)}
            onConfirm={handleDeleteTeam}
            loading={deleteLoading}
        />

        <StartSessionModal
            isOpen={startSessionModalOpen}
            onClose={() => setStartSessionModalOpen(false)}
            eventId={eventId || ""}
            teamId={sessionTeamId}
            onSessionStarted={handleSessionStarted}
        />
    </div>
  );
}
