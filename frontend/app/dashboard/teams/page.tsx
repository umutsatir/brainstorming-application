"use client";

import { useState, useEffect } from "react";
import { Plus, GripHorizontal, Search, SlidersHorizontal, LayoutGrid, Lock, MoreHorizontal, Users, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { ParticipantsList } from "@/components/teams/ParticipantsList";
import { TeamCard } from "@/components/teams/TeamCard";
import { CreateTeamModal } from "@/components/teams/CreateTeamModal";

import { DeleteConfirmationModal } from "@/components/teams/DeleteConfirmationModal";

interface Team {
  id: number;
  name: string;
  memberCount: number;
  leaderName: string;
  focus: string;
  capacity: number;
}

export default function TeamsPage() {
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(true);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [selectedTeamId, setSelectedTeamId] = useState<number | null>(null);
  
  // Delete Modal State
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [teamToDelete, setTeamToDelete] = useState<number | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  // Hardcoded eventId = 1
  const EVENT_ID = 1;

  const fetchTeams = async () => {
    try {
      const response = await api.get(`/events/${EVENT_ID}/teams`);
      setTeams(response.data);
    } catch (error) {
      console.error("Failed to fetch teams", error);
    } finally {
      setLoading(false);
    }
  };

  const [userRole, setUserRole] = useState<string | null>(null);

  useEffect(() => {
    fetchTeams();
    
    // Get user role from localStorage
    const userStr = localStorage.getItem("user");
    if (userStr) {
        try {
            const user = JSON.parse(userStr);
            // Assuming user object has a role field. Adjust if nested (e.g. user.authorities)
            setUserRole(user.role || null);
        } catch (e) {
            console.error("Failed to parse user", e);
        }
    }
  }, []);

  const canDelete = userRole === "EVENT_MANAGER" || userRole === "ROLE_EVENT_MANAGER";

  const handleTeamClick = (id: number) => {
      if (selectedTeamId === id) {
          setSelectedTeamId(null); // Toggle off
      } else {
          setSelectedTeamId(id);
      }
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

  return (
    <div className="flex flex-col gap-6">
        {/* Breadcrumb / Header */}
        <div className="flex flex-col gap-1">
            <div className="text-sm text-gray-500">Dashboard / Events / Event #1234 - Quarterly Brainstorm</div>
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold text-gray-900">Team Management</h1>
                <div className="flex items-center gap-3">
                    <Button variant="outline" className="text-gray-600 border-gray-200 hover:bg-gray-50 hover:text-gray-900 shadow-sm">
                        <Users className="mr-2 h-4 w-4" />
                        Manage Roles
                    </Button>
                    <Button 
                        className="bg-blue-600 hover:bg-blue-700 text-white shadow-md shadow-blue-500/20 transition-all hover:shadow-lg hover:translate-y-[-1px]"
                        onClick={() => setIsCreateModalOpen(true)}
                    >
                        <Plus className="mr-2 h-4 w-4" />
                        Create New Team
                    </Button>
                </div>
            </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            
            {/* Left Column: Participants (4 cols on lg, 3 on xl) */}
            <div className="lg:col-span-4 xl:col-span-3 flex flex-col gap-4">
                 <ParticipantsList teamId={selectedTeamId} />
            </div>

            {/* Right Column: Teams Grid (8 cols on lg, 9 on xl) */}
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
                                canDelete={canDelete}
                            />
                        ))}

                        {/* Add Team Card */}
                        <div 
                            className="border-2 border-dashed border-gray-200 rounded-xl p-5 flex flex-col items-center justify-center gap-2 h-full min-h-[200px] hover:border-blue-400 hover:bg-blue-50/50 transition-all cursor-pointer group"
                            onClick={() => setIsCreateModalOpen(true)}
                        >
                            <div className="h-12 w-12 rounded-full bg-gray-50 group-hover:bg-blue-100 flex items-center justify-center text-gray-400 group-hover:text-blue-600 transition-colors">
                                <Plus className="h-6 w-6" />
                            </div>
                            <span className="font-medium text-gray-500 group-hover:text-blue-600">Add Another Team</span>
                        </div>
                    </div>
                )}
            </div>
        </div>

        <CreateTeamModal 
            isOpen={isCreateModalOpen} 
            onClose={() => setIsCreateModalOpen(false)}
            onSuccess={fetchTeams}
        />
        
        <DeleteConfirmationModal 
            isOpen={deleteModalOpen}
            onClose={() => setDeleteModalOpen(false)}
            onConfirm={handleDeleteTeam}
            loading={deleteLoading}
        />
    </div>
  )
}
