import React from "react";
import { X, AlertTriangle, Info } from "lucide-react";
import { Button } from "@/components/ui/button";

interface ConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  variant?: "danger" | "primary" | "warning";
  isLoading?: boolean;
}

export function ConfirmationModal({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = "Confirm",
  cancelText = "Cancel",
  variant = "primary",
  isLoading = false,
}: ConfirmationModalProps) {
  if (!isOpen) return null;

  const getIcon = () => {
    switch (variant) {
      case "danger":
        return <AlertTriangle className="h-6 w-6 text-red-600" />;
      case "warning":
        return <AlertTriangle className="h-6 w-6 text-amber-600" />;
      default:
        return <Info className="h-6 w-6 text-blue-600" />;
    }
  };

  const getButtonColor = () => {
    switch (variant) {
      case "danger":
        return "bg-red-600 hover:bg-red-700 text-white border-transparent";
      case "warning":
        return "bg-amber-600 hover:bg-amber-700 text-white border-transparent";
      default:
        return "bg-blue-600 hover:bg-blue-700 text-white border-transparent";
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-in fade-in duration-200">
      <div className="w-full max-w-md bg-white rounded-xl shadow-2xl border border-gray-100 overflow-hidden animate-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between p-4 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
            {getIcon()}
            {title}
          </h2>
          <Button 
            variant="ghost" 
            size="icon" 
            onClick={onClose} 
            disabled={isLoading}
            className="h-8 w-8 rounded-full hover:bg-gray-200/50"
          >
            <X className="h-4 w-4 text-gray-500" />
          </Button>
        </div>

        <div className="p-6">
          <p className="text-gray-600 text-sm leading-relaxed">
            {message}
          </p>
        </div>

        <div className="flex items-center justify-end gap-3 p-4 bg-gray-50/50 border-t border-gray-100">
          <Button 
            variant="outline" 
            onClick={onClose}
            disabled={isLoading}
            className="bg-white hover:bg-gray-50"
          >
            {cancelText}
          </Button>
          <Button 
            onClick={onConfirm}
            disabled={isLoading}
            className={`${getButtonColor()} min-w-[80px]`}
          >
            {isLoading ? "Processing..." : confirmText}
          </Button>
        </div>
      </div>
    </div>
  );
}
