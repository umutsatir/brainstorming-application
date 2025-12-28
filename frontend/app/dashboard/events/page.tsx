"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Plus, Calendar, Search, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { EventCard } from "@/components/events/EventCard";
import { CreateEventModal } from "@/components/events/CreateEventModal";
import { DeleteConfirmationModal } from "@/components/teams/DeleteConfirmationModal";

interface Event {
    id: number;
    name: string;
    description: string;
    startDate: string;
    endDate: string;
    ownerName: string;
}

export default function EventsPage() {
  const router = useRouter();
  const [events, setEvents] = useState<Event[]>([]);
  const [filteredEvents, setFilteredEvents] = useState<Event[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(true);
  
  // Modal States
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [editEvent, setEditEvent] = useState<Event | undefined>(undefined);
  
  const [userRole, setUserRole] = useState<string | null>(null);

  // Delete Modal State
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [eventToDelete, setEventToDelete] = useState<number | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  // Check Access
  useEffect(() => {
    const userStr = localStorage.getItem("user");
    if (userStr) {
        try {
            const user = JSON.parse(userStr);
            // Allow both EVENT_MANAGER and TEAM_LEADER
            if (user.role !== "EVENT_MANAGER" && user.role !== "ROLE_EVENT_MANAGER" && 
                user.role !== "TEAM_LEADER" && user.role !== "ROLE_TEAM_LEADER") {
                // Not authorized
                router.push("/dashboard"); 
                return;
            }
            setUserRole(user.role);
        } catch (e) {
            router.push("/");
        }
    } else {
        router.push("/login");
    }
  }, [router]);

  const fetchEvents = async () => {
    try {
      setLoading(true);
      const response = await api.get("/events");
      setEvents(response.data);
      setFilteredEvents(response.data);
    } catch (error) {
      console.error("Failed to fetch events", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (userRole) {
        fetchEvents();
    }
  }, [userRole]);

  // Search Logic
  useEffect(() => {
    if (!searchQuery.trim()) {
        setFilteredEvents(events);
    } else {
        const lowerQuery = searchQuery.toLowerCase();
        const filtered = events.filter(event => 
            event.name.toLowerCase().includes(lowerQuery) || 
            (event.description && event.description.toLowerCase().includes(lowerQuery))
        );
        setFilteredEvents(filtered);
    }
  }, [searchQuery, events]);

  const handleDeleteClick = (id: number) => {
      setEventToDelete(id);
      setDeleteModalOpen(true);
  };

  const handleEditClick = (event: Event) => {
      setEditEvent(event);
      setIsCreateModalOpen(true);
  };

  const handleCreateClick = () => {
      setEditEvent(undefined);
      setIsCreateModalOpen(true);
  };

  const confirmDeleteEvent = async () => {
      if (!eventToDelete) return;
      
      try {
          setDeleteLoading(true);
          await api.delete(`/events/${eventToDelete}`);
          // Optimistic update
          setEvents(prev => prev.filter(e => e.id !== eventToDelete));
          setDeleteModalOpen(false);
          setEventToDelete(null);
      } catch (error) {
          console.error("Failed to delete event", error);
          alert("Failed to delete event");
          fetchEvents(); 
      } finally {
          setDeleteLoading(false);
      }
  };

  if (!userRole) return null; 

  const canManageEvents = userRole === "EVENT_MANAGER" || userRole === "ROLE_EVENT_MANAGER";

  return (
    <div className="flex flex-col gap-8">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
                <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Event Management</h1>
                <p className="text-gray-500 mt-1">
                    {canManageEvents 
                        ? "Create and manage your organization's brainstorming events." 
                        : "View events you are participating in or leading."}
                </p>
            </div>
            {canManageEvents && (
                <Button 
                    onClick={handleCreateClick}
                    className="bg-blue-600 hover:bg-blue-700 text-white shadow-lg shadow-blue-600/20"
                >
                    <Plus className="mr-2 h-4 w-4" /> Create New Event
                </Button>
            )}
        </div>

        {/* Search Bar */}
        <div className="bg-white p-4 rounded-xl border border-gray-100 shadow-sm flex items-center gap-4">
            <Search className="h-5 w-5 text-gray-400" />
            <input 
                className="flex-1 outline-none text-sm placeholder:text-gray-400" 
                placeholder="Search events by name or description..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
            />
        </div>

        {/* Events Grid */}
        {loading ? (
            <div className="flex justify-center items-center h-64">
                <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
            </div>
        ) : filteredEvents.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredEvents.map((event) => (
                    <EventCard 
                        key={event.id} 
                        event={event} 
                        onDelete={handleDeleteClick}
                        onEdit={handleEditClick}
                        canManage={canManageEvents}
                    />
                ))}
            </div>
        ) : (
            <div className="flex flex-col items-center justify-center h-64 bg-gray-50/50 rounded-2xl border-2 border-dashed border-gray-200">
                <div className="h-12 w-12 bg-gray-100 rounded-full flex items-center justify-center mb-4 text-gray-400">
                    <Calendar className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-medium text-gray-900">
                    {searchQuery ? "No matching events found" : "No events found"}
                </h3>
                <p className="text-gray-500 text-sm mt-1">
                    {searchQuery ? "Try adjusting your search terms." : "Get started by creating your first event."}
                </p>
            </div>
        )}

        {/* Modals */}
        <CreateEventModal 
            isOpen={isCreateModalOpen}
            onClose={() => setIsCreateModalOpen(false)}
            onSuccess={fetchEvents}
            initialData={editEvent}
        />
        
        <DeleteConfirmationModal 
            isOpen={deleteModalOpen}
            onClose={() => setDeleteModalOpen(false)}
            onConfirm={confirmDeleteEvent}
            loading={deleteLoading}
            title="Delete Event?"
            description="Are you sure you want to delete this event? All associated teams and data will be permanently removed."
        />
    </div>
  );
}
