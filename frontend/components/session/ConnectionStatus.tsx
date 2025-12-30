"use client";

interface ConnectionStatusProps {
    isConnected: boolean;
    isReconnecting: boolean;
    onReconnect: () => void;
}

export function ConnectionStatus({
    isConnected,
    isReconnecting,
    onReconnect,
}: ConnectionStatusProps) {
    if (isConnected) {
        return null;
    }

    return (
        <div className="fixed bottom-4 right-4 z-50">
            <div className="bg-white border border-amber-300 rounded-lg p-4 shadow-xl max-w-sm">
                <div className="flex items-start gap-3">
                    {isReconnecting ? (
                        <div className="flex-shrink-0">
                            <svg
                                className="w-5 h-5 text-amber-600 animate-spin"
                                fill="none"
                                viewBox="0 0 24 24"
                            >
                                <circle
                                    className="opacity-25"
                                    cx="12"
                                    cy="12"
                                    r="10"
                                    stroke="currentColor"
                                    strokeWidth="4"
                                />
                                <path
                                    className="opacity-75"
                                    fill="currentColor"
                                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                />
                            </svg>
                        </div>
                    ) : (
                        <div className="flex-shrink-0">
                            <svg
                                className="w-5 h-5 text-red-500"
                                fill="currentColor"
                                viewBox="0 0 20 20"
                            >
                                <path
                                    fillRule="evenodd"
                                    d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                                    clipRule="evenodd"
                                />
                            </svg>
                        </div>
                    )}
                    <div className="flex-1">
                        <h3 className="text-sm font-semibold text-gray-900">
                            {isReconnecting ? "Reconnecting..." : "Connection Lost"}
                        </h3>
                        <p className="text-xs text-gray-600 mt-1">
                            {isReconnecting
                                ? "Attempting to restore your connection. Please wait..."
                                : "Unable to connect to the session. Your progress is saved."}
                        </p>
                        {!isReconnecting && (
                            <button
                                onClick={onReconnect}
                                className="mt-2 text-xs font-medium text-amber-600 hover:text-amber-700 transition-colors"
                            >
                                Try Again →
                            </button>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
