"use client";

import { useState, useEffect } from "react";
import { X, Loader2, Calendar as CalendarIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { api } from "@/lib/api";

interface CreateEventModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  initialData?: any; // or Event interface
}

export function CreateEventModal({ isOpen, onClose, onSuccess, initialData }: CreateEventModalProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    startDate: "",
    endDate: ""
  });

  useEffect(() => {
    if (initialData) {
        setFormData({
            name: initialData.name || "",
            description: initialData.description || "",
            startDate: initialData.startDate ? new Date(initialData.startDate).toISOString().split('T')[0] : "",
            endDate: initialData.endDate ? new Date(initialData.endDate).toISOString().split('T')[0] : ""
        });
    } else {
        setFormData({ name: "", description: "", startDate: "", endDate: "" });
    }
  }, [initialData, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (initialData?.id) {
          // Edit Mode
          await api.patch(`/events/${initialData.id}`, formData);
      } else {
          // Create Mode
          await api.post("/events", formData);
      }
      onSuccess();
      onClose();
      if (!initialData) {
          setFormData({ name: "", description: "", startDate: "", endDate: "" });
      }
    } catch (err: any) {
        console.error("Save event error:", err);
        setError(err.response?.data?.message || "Failed to save event");
    } finally {
        setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { id, value } = e.target;
    setFormData(prev => ({ ...prev, [id]: value }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
        <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg border border-gray-100 overflow-hidden scale-100 animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between p-6 border-b border-gray-100 bg-gray-50/50">
                <div>
                     <h2 className="text-xl font-bold text-gray-900">{initialData ? "Edit Event" : "Create New Event"}</h2>
                     <p className="text-sm text-gray-500 mt-1">{initialData ? "Update event details." : "Organize a new brainstorming session."}</p>
                </div>
                <Button variant="ghost" size="icon" onClick={onClose} className="h-8 w-8 rounded-full hover:bg-gray-200/50">
                    <X className="h-4 w-4 text-gray-500" />
                </Button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-6 space-y-5">
                {error && (
                    <div className="p-4 text-sm text-red-600 bg-red-50 border border-red-100 rounded-lg">
                        {error}
                    </div>
                )}
                
                <div className="space-y-2">
                    <Label htmlFor="name">Event Name</Label>
                    <Input 
                        id="name" 
                        placeholder="e.g. Q4 Innovation Hackathon" 
                        value={formData.name}
                        onChange={handleChange}
                        required
                    />
                </div>

                <div className="space-y-2">
                    <Label htmlFor="description">Description</Label>
                    <Textarea 
                        id="description" 
                        placeholder="Briefly describe the purpose of this event..." 
                        value={formData.description}
                        onChange={handleChange}
                        className="resize-none h-24"
                    />
                </div>

                <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                        <Label htmlFor="startDate">Start Date</Label>
                        <div className="relative">
                            <Input 
                                id="startDate" 
                                type="date" 
                                value={formData.startDate}
                                onChange={handleChange}
                                required
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="endDate">End Date</Label>
                        <div className="relative">
                            <Input 
                                id="endDate" 
                                type="date" 
                                value={formData.endDate}
                                onChange={handleChange}
                                required
                            />
                        </div>
                    </div>
                </div>

                <div className="flex justify-end gap-3 pt-4 border-t border-gray-50 mt-2">
                    <Button type="button" variant="ghost" onClick={onClose} disabled={loading}>
                        Cancel
                    </Button>
                    <Button type="submit" className="bg-blue-600 hover:bg-blue-700 text-white" disabled={loading}>
                        {loading ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
                        {initialData ? "Update Event" : "Create Event"}
                    </Button>
                </div>
            </form>
        </div>
    </div>
  );
}
