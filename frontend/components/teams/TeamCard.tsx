import { useState } from "react";
import { MoreHorizontal, Plus, Lock, Trash2, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";

interface TeamProps {
  id: number;
  name: string;
  member_count: number;
  leader_name: string;
  focus: string;
  capacity: number;
}

export function TeamCard({ 
    team,
    isSelected,
    onClick,
    onDelete,
    onEdit,
    canDelete = false
}: { 
    team: TeamProps;
    isSelected: boolean;
    onClick: () => void;
    onDelete: () => void;
    onEdit: (team: TeamProps) => void;
    canDelete?: boolean;
}) {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const capacity = team.capacity || 6; 
  const isFull = team.member_count >= capacity;
  const status = isFull ? "Full" : "Open";
  const progress = (team.member_count / capacity) * 100;
  
  return (
    <div 
        className={`bg-white rounded-xl shadow-sm border p-5 flex flex-col gap-4 cursor-pointer transition-all ${isSelected ? 'border-blue-500 ring-1 ring-blue-500' : 'border-gray-100 hover:border-blue-200'}`}
        onClick={onClick}
    >
        <div className="flex items-start justify-between">
            <div>
                <h3 className="font-bold text-lg text-gray-900">{team.name}</h3>
                <p className="text-xs text-gray-500 mt-1">Focus: {team.focus}</p>
                <p className="text-xs text-gray-400">Leader: {team.leader_name || "Unassigned"}</p>
            </div>
            
            <div className="relative">
                {canDelete && (
                    <Button 
                        variant="ghost" 
                        size="icon" 
                        className="h-8 w-8"
                        onClick={(e) => {
                            e.stopPropagation(); // Prevent selection when clicking menu
                            setIsMenuOpen(!isMenuOpen);
                        }}
                    >
                        <MoreHorizontal className="h-4 w-4 text-gray-400" />
                    </Button>
                )}
                
                {isMenuOpen && (
                    <>
                        <div 
                            className="fixed inset-0 z-10" 
                            onClick={(e) => {
                                e.stopPropagation();
                                setIsMenuOpen(false);
                            }} 
                        />
                        <div className="absolute right-0 top-full mt-1 w-32 bg-white rounded-lg shadow-lg border border-gray-100 z-20 overflow-hidden">
                             <button 
                                className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    setIsMenuOpen(false);
                                    onEdit(team);
                                }}
                            >
                                <Pencil className="h-3 w-3" />
                                Edit
                            </button>
                            <button 
                                className="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    setIsMenuOpen(false);
                                    onDelete();
                                }}
                            >
                                <Trash2 className="h-3 w-3" />
                                Delete
                            </button>
                        </div>
                    </>
                )}
            </div>
        </div>
        
        <div className="flex items-center justify-between text-sm">
            <span className="font-medium text-gray-700">{team.member_count}/{capacity} Members</span>
            <span className={`font-medium text-xs px-2 py-0.5 rounded-full ${isFull ? 'text-red-600 bg-red-50' : 'text-green-600 bg-green-50'}`}>
                {status}
            </span>
        </div>
        
        {/* Progress Bar */}
        <div className="h-2 w-full bg-gray-100 rounded-full overflow-hidden">
            <div 
                className={`h-full rounded-full ${isFull ? 'bg-red-500' : 'bg-blue-600'}`} 
                style={{ width: `${progress}%` }} 
            />
        </div>

        <div className="flex items-center justify-between mt-2 pt-4 border-t border-gray-50">
             <div className="flex -space-x-2">
                {/* Placeholder avatars since checking members requires separate API call per team currently (n+1 problem). 
                    Ideally backend returns members or we fetch them. 
                    For this card I will just show placeholders based on count. */}
                {Array.from({ length: Math.min(3, team.member_count) }).map((_, i) => (
                    <div key={i} className="h-8 w-8 rounded-full ring-2 ring-white bg-gray-200" />
                ))}
                {team.member_count > 3 && (
                    <div className="h-8 w-8 rounded-full ring-2 ring-white bg-gray-100 flex items-center justify-center text-xs text-gray-500 font-medium">
                        +{team.member_count - 3}
                    </div>
                )}
             </div>
             
             {isFull ? (
                 <div className="flex items-center text-xs text-gray-400 font-medium gap-1">
                    <Lock className="h-3 w-3" /> Full
                 </div>
             ) : (
                 <div className="text-xs text-green-600 font-medium">
                    Open
                 </div>
             )}
        </div>
    </div>
  );
}
