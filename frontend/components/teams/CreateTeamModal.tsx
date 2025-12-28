"use client";

import { useState, useEffect } from "react";
import { X, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api } from "@/lib/api";

interface CreateTeamModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  eventId: number;
  initialData?: any;
}

export function CreateTeamModal({ isOpen, onClose, onSuccess, eventId, initialData }: CreateTeamModalProps) {
  const [name, setName] = useState("");
  const [focus, setFocus] = useState("");
  const [capacity, setCapacity] = useState("6");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (initialData) {
        setName(initialData.name || "");
        setFocus(initialData.focus || "");
        setCapacity(initialData.capacity?.toString() || "6");
    } else {
        setName("");
        setFocus("");
        setCapacity("6");
    }
  }, [initialData, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (initialData?.id) {
          // Edit Mode
          await api.patch(`/teams/${initialData.id}`, {
             name,
             focus,
             capacity: parseInt(capacity),
             eventId 
          });
      } else {
          // Create Mode
          await api.post(`/events/${eventId}/teams`, {
            name,
            focus,
            capacity: parseInt(capacity),
          });
      }
      onSuccess();
      onClose();
      if (!initialData) {
        setName("");
        setFocus("");
        setCapacity("6");
      }
    } catch (err: any) {
        console.error("Save team error:", err);
        setError(err.response?.data?.message || "Failed to save team");
    } finally {
        setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
        <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg border border-gray-100 overflow-hidden scale-100 animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between p-6 border-b border-gray-100 bg-gray-50/50">
                <div>
                     <h2 className="text-xl font-bold text-gray-900">{initialData ? "Edit Team" : "Create New Team"}</h2>
                     <p className="text-sm text-gray-500 mt-1">{initialData ? "Update team details." : "Add a new collaborative group to this event."}</p>
                </div>
                <Button variant="ghost" size="icon" onClick={onClose} className="h-8 w-8 rounded-full hover:bg-gray-200/50">
                    <X className="h-4 w-4 text-gray-500" />
                </Button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-6 space-y-5">
                {error && (
                    <div className="p-4 text-sm text-red-600 bg-red-50 border border-red-100 rounded-lg flex items-center gap-2">
                        <span className="h-1.5 w-1.5 rounded-full bg-red-500 flex-shrink-0" />
                        {error}
                    </div>
                )}
                
                <div className="space-y-2">
                    <Label htmlFor="teamName" className="text-gray-700 font-medium">Team Name</Label>
                    <Input 
                        id="teamName" 
                        placeholder="e.g. Alpha Squad" 
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        required
                        className="h-11 bg-gray-50/50 border-gray-200 focus:bg-white transition-all"
                    />
                </div>

                <div className="grid grid-cols-2 gap-5">
                    <div className="space-y-2">
                        <Label htmlFor="focus" className="text-gray-700 font-medium">Focus Area</Label>
                        <Input 
                            id="focus" 
                            placeholder="e.g. Design" 
                            value={focus}
                            onChange={(e) => setFocus(e.target.value)}
                            className="h-11 bg-gray-50/50 border-gray-200 focus:bg-white transition-all"
                        />
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="capacity" className="text-gray-700 font-medium">Max Members</Label>
                        <Input 
                            id="capacity" 
                            type="number"
                            min="1"
                            max="6"
                            value={capacity}
                            onChange={(e) => setCapacity(e.target.value)}
                            required
                            className="h-11 bg-gray-50/50 border-gray-200 focus:bg-white transition-all"
                        />
                    </div>
                </div>

                <div className="flex justify-end gap-3 pt-4 border-t border-gray-50 mt-2">
                    <Button type="button" variant="ghost" onClick={onClose} disabled={loading} className="text-gray-600 hover:text-gray-900 hover:bg-gray-100">
                        Cancel
                    </Button>
                    <Button type="submit" className="bg-blue-600 hover:bg-blue-700 text-white shadow-md shadow-blue-500/20 px-6" disabled={loading}>
                        {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : (initialData ? "Update Team" : "Create Team")}
                    </Button>
                </div>
            </form>
        </div>
    </div>
  );
}
