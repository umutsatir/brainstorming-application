"use client";

import { useEffect, useState } from "react";
import { GripHorizontal, Search, SlidersHorizontal, Loader2, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";

interface Participant {
  id: number;
  full_name: string;
  role: string;
  status: string;
}

export function ParticipantsList({ teamId }: { teamId: number | null }) {
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  const fetchParticipants = async () => {
    setLoading(true);
    // don't clear participants immediately to avoid flickering if possible, but here we switch data source
    try {
      let response;
      if (teamId) {
          response = await api.get(`/teams/${teamId}/members`);
      } else {
          // Default: all participants
          response = await api.get("/participants");
      }
      setParticipants(response.data);
    } catch (error) {
      console.error("Failed to fetch participants", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchParticipants();
  }, [teamId]);

  const handleRemoveMember = async (userId: number, e: React.MouseEvent) => {
      e.stopPropagation(); // Prevent row click
      if (!teamId) return; // Can only remove if viewing a team

      if (!confirm("Are you sure you want to remove this member from the team?")) return;

      try {
          await api.delete(`/teams/${teamId}/members/${userId}`);
          // Refresh list
          fetchParticipants();
      } catch (error) {
          console.error("Failed to remove member", error);
          alert("Failed to remove member");
      }
  };

  const filteredParticipants = participants.filter(p => 
    p.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    p.role?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const listTitle = teamId ? "Team Members" : "All Participants";

  const getInitials = (name: string) => {
    return name?.split(" ").map(n => n[0]).join("").toUpperCase().substring(0, 2) || "??";
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden flex flex-col h-[calc(100vh-12rem)]">
        <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-white sticky top-0 z-10">
            <h2 className="font-semibold text-gray-900">{listTitle}</h2>
            <span className="text-xs font-medium text-gray-500 bg-gray-100 px-2 py-1 rounded-full">{filteredParticipants.length}</span>
        </div>
        <div className="p-4 border-b border-gray-100">
             <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input 
                    className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                    placeholder="Search by name or role..."
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
            ) : filteredParticipants.length > 0 ? (
                filteredParticipants.map((p) => (
                    <div key={p.id} className="flex items-center gap-3 p-3 hover:bg-gray-50 rounded-lg cursor-grab group transition-colors">
                        <GripHorizontal className="text-gray-300 h-4 w-4 opacity-0 group-hover:opacity-100" />
                        <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-medium text-sm">
                            {getInitials(p.full_name)}
                        </div>
                        <div className="flex-1 min-w-0">
                            <div className="font-medium text-sm text-gray-900 truncate">{p.full_name}</div>
                            <div className="text-xs text-gray-500 truncate">{p.role}</div>
                        </div>
                        
                        {/* Remove Button - Only visible if viewing a specific team */}
                        {teamId && (
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
                    No participants found
                </div>
            )}
        </div>
     </div>
  );
}
