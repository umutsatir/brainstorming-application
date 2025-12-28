"use client";

import { Calendar, Trash2, ArrowRight, User, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";

interface EventProps {
  id: number;
  name: string;
  description: string;
  startDate: string;
  endDate: string;
  ownerName: string;
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
              {new Date(event.startDate).toLocaleDateString()} - {new Date(event.endDate).toLocaleDateString()}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <User className="h-3.5 w-3.5" />
            <span>Owner: {event.ownerName || "Unknown"}</span>
          </div>
        </div>
      </div>

      <div className="mt-6 flex items-center justify-between pt-4 border-t border-gray-50">
        <span className="text-sm font-medium text-blue-600 flex items-center gap-1 group-hover:gap-2 transition-all">
          View Teams <ArrowRight className="h-4 w-4" />
        </span>
        
        {canManage && (
            <div className="flex items-center gap-1">
                <Button
                    variant="ghost"
                    size="icon"
                    className="text-gray-400 hover:text-blue-600 hover:bg-blue-50"
                    onClick={handleEdit}
                >
                    <Pencil className="h-4 w-4" />
                </Button>
                <Button
                    variant="ghost"
                    size="icon"
                    className="text-gray-400 hover:text-red-600 hover:bg-red-50"
                    onClick={handleDelete}
                >
                    <Trash2 className="h-4 w-4" />
                </Button>
            </div>
        )}
      </div>
    </div>
  );
}
