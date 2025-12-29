"use client";

import { useState, useEffect } from "react";
import { X, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { api } from "@/lib/api";

interface CreateTopicModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  eventId: number;
  initialData?: any;
}

export function CreateTopicModal({ isOpen, onClose, onSuccess, eventId, initialData }: CreateTopicModalProps) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (initialData) {
        setTitle(initialData.title || "");
        setDescription(initialData.description || "");
    } else {
        setTitle("");
        setDescription("");
    }
  }, [initialData, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (initialData?.id) {
          // Edit Mode
          await api.patch(`/topics/${initialData.id}`, {
             title,
             description
          });
      } else {
          // Create Mode
          await api.post(`/events/${eventId}/topics`, {
            title,
            description
          });
      }
      onSuccess();
      onClose();
      if (!initialData) {
        setTitle("");
        setDescription("");
      }
    } catch (err: any) {
        console.error("Save topic error:", err);
        setError(err.response?.data?.message || "Failed to save topic");
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
                     <h2 className="text-xl font-bold text-gray-900">{initialData ? "Edit Topic" : "Create New Topic"}</h2>
                     <p className="text-sm text-gray-500 mt-1">{initialData ? "Update topic details." : "Add a new discussion topic to this event."}</p>
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
                    <Label htmlFor="title" className="text-gray-700 font-medium">Topic Title</Label>
                    <Input 
                        id="title" 
                        value={title} 
                        onChange={(e) => setTitle(e.target.value)} 
                        placeholder="e.g., Q3 Marketing Strategy"
                        required
                        className="bg-gray-50 border-gray-200 focus:bg-white transition-all"
                    />
                </div>

                <div className="space-y-2">
                    <Label htmlFor="description" className="text-gray-700 font-medium">Description</Label>
                    <Textarea 
                        id="description" 
                        value={description} 
                        onChange={(e) => setDescription(e.target.value)} 
                        placeholder="Briefly describe what this topic is about..."
                        className="bg-gray-50 border-gray-200 focus:bg-white transition-all min-h-[100px]"
                    />
                </div>

                <div className="flex items-center justify-end gap-3 pt-2">
                    <Button type="button" variant="outline" onClick={onClose} disabled={loading}>
                        Cancel
                    </Button>
                    <Button type="submit" className="bg-blue-600 hover:bg-blue-700 text-white" disabled={loading}>
                        {loading ? (
                            <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Saving...
                            </>
                        ) : (
                            initialData ? "Update Topic" : "Create Topic"
                        )}
                    </Button>
                </div>
            </form>
        </div>
    </div>
  );
}
