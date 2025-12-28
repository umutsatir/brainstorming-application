"use client";

import { X, AlertTriangle, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";

interface DeleteConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  loading?: boolean;
}

export function DeleteConfirmationModal({ isOpen, onClose, onConfirm, loading = false }: DeleteConfirmationModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
        <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden scale-100 animate-in zoom-in-95 duration-200 border border-gray-100">
            <div className="p-6 flex flex-col items-center text-center gap-4">
                <div className="h-16 w-16 rounded-full bg-red-50 flex items-center justify-center text-red-500 mb-2 ring-8 ring-red-50/50">
                    <AlertTriangle className="h-8 w-8" />
                </div>
                
                <div className="space-y-2">
                    <h2 className="text-xl font-bold text-gray-900">Delete Team?</h2>
                    <p className="text-sm text-gray-500 leading-relaxed px-2">
                        This action cannot be undone. All data associated with this team will be permanently removed.
                    </p>
                </div>

                <div className="flex gap-3 w-full mt-4">
                    <Button 
                        variant="outline" 
                        className="flex-1 border-gray-200 hover:bg-gray-50 hover:text-gray-900"
                        onClick={onClose}
                        disabled={loading}
                    >
                        Cancel
                    </Button>
                    <Button 
                        variant="destructive"
                        className="flex-1 shadow-md shadow-red-500/20"
                        onClick={onConfirm}
                        disabled={loading}
                    >
                         {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Delete Team"}
                    </Button>
                </div>
            </div>
        </div>
    </div>
  );
}
