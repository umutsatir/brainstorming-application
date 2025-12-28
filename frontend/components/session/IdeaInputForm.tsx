"use client";

import { useState, useEffect, useMemo } from "react";

interface IdeaInputFormProps {
    onSubmit: (ideas: string[]) => void;
    isDisabled: boolean;
    isSubmitted: boolean;
    submittedIdeas: string[];
    isLoading: boolean;
    error: string | null;
}

export function IdeaInputForm({
    onSubmit,
    isDisabled,
    isSubmitted,
    submittedIdeas,
    isLoading,
    error,
}: IdeaInputFormProps) {
    const [ideas, setIdeas] = useState<string[]>(["", "", ""]);
    const [validationErrors, setValidationErrors] = useState<string[]>([]);

    // Reset form when round changes (submittedIdeas changes to empty)
    useEffect(() => {
        if (!isSubmitted && submittedIdeas.length === 0) {
            setIdeas(["", "", ""]);
            setValidationErrors([]);
        }
    }, [isSubmitted, submittedIdeas]);

    // Show submitted ideas if already submitted
    useEffect(() => {
        if (isSubmitted && submittedIdeas.length === 3) {
            setIdeas(submittedIdeas);
        }
    }, [isSubmitted, submittedIdeas]);

    const handleIdeaChange = (index: number, value: string) => {
        if (isDisabled || isSubmitted) return;
        
        const newIdeas = [...ideas];
        newIdeas[index] = value;
        setIdeas(newIdeas);
        
        // Clear validation errors on change
        if (validationErrors.length > 0) {
            setValidationErrors([]);
        }
    };

    const validateIdeas = (): boolean => {
        const errors: string[] = [];
        const trimmedIdeas = ideas.map((idea) => idea.trim());

        // Check for empty ideas
        const emptyIndices = trimmedIdeas
            .map((idea, i) => (idea === "" ? i + 1 : null))
            .filter(Boolean);
        if (emptyIndices.length > 0) {
            errors.push(`Idea ${emptyIndices.join(", ")} cannot be empty`);
        }

        // Check for duplicates
        const seen = new Set<string>();
        const duplicates: number[] = [];
        trimmedIdeas.forEach((idea, i) => {
            if (idea && seen.has(idea.toLowerCase())) {
                duplicates.push(i + 1);
            }
            seen.add(idea.toLowerCase());
        });
        if (duplicates.length > 0) {
            errors.push(`Ideas must be unique (duplicates at position ${duplicates.join(", ")})`);
        }

        setValidationErrors(errors);
        return errors.length === 0;
    };

    const handleSubmit = () => {
        if (!validateIdeas()) return;
        onSubmit(ideas.map((idea) => idea.trim()));
    };

    const canSubmit = useMemo(() => {
        const trimmedIdeas = ideas.map((idea) => idea.trim());
        const allFilled = trimmedIdeas.every((idea) => idea.length > 0);
        const allUnique = new Set(trimmedIdeas.map((i) => i.toLowerCase())).size === 3;
        return allFilled && allUnique && !isDisabled && !isSubmitted && !isLoading;
    }, [ideas, isDisabled, isSubmitted, isLoading]);

    const getInputStyles = (index: number) => {
        const baseStyles =
            "w-full bg-zinc-800 border rounded-lg p-4 text-zinc-100 placeholder-zinc-500 focus:outline-none focus:ring-2 transition-all resize-none";
        
        if (isSubmitted) {
            return `${baseStyles} border-emerald-500/50 bg-emerald-500/5 cursor-not-allowed`;
        }
        if (isDisabled) {
            return `${baseStyles} border-zinc-700 bg-zinc-800/50 cursor-not-allowed opacity-60`;
        }
        if (ideas[index].trim()) {
            return `${baseStyles} border-zinc-600 focus:border-emerald-500 focus:ring-emerald-500/20`;
        }
        return `${baseStyles} border-zinc-700 focus:border-zinc-500 focus:ring-zinc-500/20`;
    };

    return (
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-1 flex items-center gap-2">
                <svg
                    className="w-5 h-5 text-zinc-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
                    />
                </svg>
                {isSubmitted ? "Your Submitted Ideas" : "Enter Your Ideas"}
            </h2>
            <p className="text-sm text-zinc-400 mb-4">
                {isSubmitted
                    ? "You have submitted your ideas for this round."
                    : isDisabled
                    ? "Submissions are currently disabled."
                    : "Submit exactly 3 unique, non-empty ideas."}
            </p>

            <div className="space-y-4">
                {[0, 1, 2].map((index) => (
                    <div key={index} className="relative">
                        <label className="block text-sm font-medium text-zinc-400 mb-2">
                            Idea {index + 1}
                        </label>
                        <div className="relative">
                            <textarea
                                value={ideas[index]}
                                onChange={(e) => handleIdeaChange(index, e.target.value)}
                                placeholder={`Enter your ${index === 0 ? "first" : index === 1 ? "second" : "third"} idea...`}
                                disabled={isDisabled || isSubmitted}
                                rows={2}
                                maxLength={500}
                                className={getInputStyles(index)}
                            />
                            <div className="absolute bottom-2 right-2 text-xs text-zinc-500">
                                {ideas[index].length}/500
                            </div>
                            {isSubmitted && (
                                <div className="absolute top-2 right-2">
                                    <svg
                                        className="w-5 h-5 text-emerald-400"
                                        fill="currentColor"
                                        viewBox="0 0 20 20"
                                    >
                                        <path
                                            fillRule="evenodd"
                                            d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                            clipRule="evenodd"
                                        />
                                    </svg>
                                </div>
                            )}
                        </div>
                    </div>
                ))}
            </div>

            {/* Validation errors */}
            {validationErrors.length > 0 && (
                <div className="mt-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
                    <ul className="text-sm text-red-400 space-y-1">
                        {validationErrors.map((error, i) => (
                            <li key={i} className="flex items-center gap-2">
                                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                                    <path
                                        fillRule="evenodd"
                                        d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                                        clipRule="evenodd"
                                    />
                                </svg>
                                {error}
                            </li>
                        ))}
                    </ul>
                </div>
            )}

            {/* API error */}
            {error && (
                <div className="mt-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
                    <p className="text-sm text-red-400 flex items-center gap-2">
                        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <path
                                fillRule="evenodd"
                                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                                clipRule="evenodd"
                            />
                        </svg>
                        {error}
                    </p>
                </div>
            )}

            {/* Submit button */}
            {!isSubmitted && (
                <div className="mt-6">
                    <button
                        onClick={handleSubmit}
                        disabled={!canSubmit}
                        className={`w-full py-3 px-4 rounded-lg font-semibold text-sm transition-all flex items-center justify-center gap-2 ${
                            canSubmit
                                ? "bg-emerald-500 hover:bg-emerald-600 text-white"
                                : "bg-zinc-700 text-zinc-400 cursor-not-allowed"
                        }`}
                    >
                        {isLoading ? (
                            <>
                                <svg
                                    className="animate-spin h-5 w-5"
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
                                Submitting...
                            </>
                        ) : (
                            <>
                                <svg
                                    className="w-5 h-5"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        strokeLinecap="round"
                                        strokeLinejoin="round"
                                        strokeWidth={2}
                                        d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
                                    />
                                </svg>
                                Submit Ideas
                            </>
                        )}
                    </button>
                </div>
            )}

            {isSubmitted && (
                <div className="mt-4 p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg">
                    <p className="text-sm text-emerald-400 flex items-center gap-2">
                        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <path
                                fillRule="evenodd"
                                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                clipRule="evenodd"
                            />
                        </svg>
                        Ideas submitted successfully! Waiting for the next round...
                    </p>
                </div>
            )}
        </div>
    );
}
