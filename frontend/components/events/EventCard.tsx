"use client";

import { Calendar, Trash2, ArrowRight, User, Pencil, MessageSquare, Users } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";

interface EventProps {
  id: number;
  name: string;
  description: string;
  start_date: string;
  end_date: string;
  owner_name: string;
}

interface EventCardProps {
  event: EventProps;
  onDelete: (id: number) => void;
  onEdit: (event: EventProps) => void;
  canManage: boolean;
}

export function EventCard({ event, onDelete, onEdit, canManage }: EventCardProps) {
  const router = useRouter();

  const handleCardClick = () => {
    router.push(`/dashboard/teams?eventId=${event.id}`);
  };

  const handleTopicsClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    router.push(`/dashboard/topics?eventId=${event.id}`);
  };

  const handleDelete = (e: React.MouseEvent) => {
    e.stopPropagation();
    onDelete(event.id);
  };

  const handleEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    onEdit(event);
  };

  return (
    <div 
      onClick={handleCardClick}
      className="group relative bg-white rounded-xl border border-gray-200 p-6 shadow-sm hover:shadow-md hover:border-blue-200 transition-all cursor-pointer flex flex-col justify-between h-full"
    >
      <div className="space-y-4">
        <div className="flex justify-between items-start">
          <div className="space-y-1">
            <h3 className="font-bold text-lg text-gray-900 group-hover:text-blue-600 transition-colors">
              {event.name}
            </h3>
            <p className="text-sm text-gray-500 line-clamp-2">
              {event.description || "No description provided."}
            </p>
          </div>
          <div className="p-2 bg-blue-50 text-blue-600 rounded-lg">
            <Calendar className="h-5 w-5" />
          </div>
        </div>

        <div className="flex flex-col gap-2 text-sm text-gray-500">
          <div className="flex items-center gap-2">
            <Calendar className="h-3.5 w-3.5" />
            <span>
              {new Date(event.start_date).toLocaleDateString()} - {new Date(event.end_date).toLocaleDateString()}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <User className="h-3.5 w-3.5" />
            <span>Owner: {event.owner_name || "Unknown"}</span>
          </div>
        </div>
      </div>

      <div className="mt-6 pt-4 border-t border-gray-100 flex items-center justify-between gap-2">
        <div className="flex gap-2 w-full">
             <Button 
                variant="secondary"
                size="sm"
                className="flex-1 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 border border-indigo-100 shadow-sm"
                onClick={handleTopicsClick}
            >
                <MessageSquare className="mr-2 h-3.5 w-3.5" /> Topics
            </Button>
            <Button 
                variant="secondary"
                size="sm"
                className="flex-1 bg-blue-50 text-blue-600 hover:bg-blue-100 border border-blue-100 shadow-sm"
                onClick={(e) => {
                    e.stopPropagation();
                    router.push(`/dashboard/teams?eventId=${event.id}`);
                }}
            >
                <Users className="mr-2 h-3.5 w-3.5" /> Teams
            </Button>
        </div>
        
        {canManage && (
            <div className="flex items-center border-l border-gray-200 pl-2 ml-1">
                <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8 text-gray-400 hover:text-blue-600 hover:bg-blue-50"
                    onClick={handleEdit}
                >
                    <Pencil className="h-3.5 w-3.5" />
                </Button>
                <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8 text-gray-400 hover:text-red-600 hover:bg-red-50"
                    onClick={handleDelete}
                >
                    <Trash2 className="h-3.5 w-3.5" />
                </Button>
            </div>
        )}
      </div>
    </div>
  );
}
