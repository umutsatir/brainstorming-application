import { useState, useEffect } from "react";
import { X, Loader2, Play } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Select } from "@/components/ui/select";
import { api } from "@/lib/api";

interface Topic {
  id: number;
  title: string;
}

interface StartSessionModalProps {
  isOpen: boolean;
  onClose: () => void;
  eventId: string | number;
  teamId: number | null;
  onSessionStarted: (sessionId: number) => void;
}

export function StartSessionModal({ 
    isOpen, 
    onClose, 
    eventId, 
    teamId,
    onSessionStarted 
}: StartSessionModalProps) {
  const [topics, setTopics] = useState<Topic[]>([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  
  const [selectedTopicId, setSelectedTopicId] = useState<string>("");
  const [roundCount, setRoundCount] = useState<string>("6");

  useEffect(() => {
    if (isOpen && eventId) {
      fetchTopics();
    } else if (!isOpen) {
      // Reset form state when modal closes
      setSelectedTopicId("");
      setRoundCount("6");
      setLoading(false);
      setSubmitting(false);
    }
  }, [isOpen, eventId]);

  const fetchTopics = async () => {
    setLoading(true);
    try {
      const response = await api.get(`/events/${eventId}/topics`);
      setTopics(response.data);
      // Auto-select first topic if available
      if (response.data.length > 0) {
        setSelectedTopicId(response.data[0].id.toString());
      }
    } catch (error) {
      console.error("Failed to fetch topics", error);
    } finally {
      setLoading(false);
    }
  };

  const handleStart = async () => {
    if (!teamId || !selectedTopicId) {
      console.error("Cannot start session: teamId or topicId is missing", { teamId, selectedTopicId });
      alert("Error: Team ID or Topic ID is missing. Please close the modal and try again.");
      return;
    }

    setSubmitting(true);
    try {
      // Step 1: Create the session
      // IMPORTANT: Backend expects snake_case due to Jackson configuration
      const requestBody = {
        team_id: teamId,
        topic_id: parseInt(selectedTopicId),
        round_count: parseInt(roundCount)
      };

      const response = await api.post("/sessions", requestBody);

      const sessionId = response.data.id;

      // Step 2: Start the session immediately
      await api.post(`/sessions/${sessionId}/start`);

      // Step 3: Navigate to session page
      onSessionStarted(sessionId);
      onClose();
    } catch (error: any) {
      console.error("Failed to start session", error);
<<<<<<< Updated upstream
      alert(`Failed to start session: ${error.response?.data?.message || error.message}`);
=======
      const errorMessage = error.response?.data?.message || error.message || "Unknown error occurred";
      alert(`Failed to start session: ${errorMessage}`);
>>>>>>> Stashed changes
    } finally {
      setSubmitting(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="w-full max-w-md bg-white rounded-xl shadow-2xl border border-gray-100 overflow-hidden animate-in fade-in zoom-in duration-200">
        <div className="flex items-center justify-between p-4 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-lg font-semibold text-gray-900">Start Brainstorming Session</h2>
          <Button variant="ghost" size="icon" onClick={onClose} className="h-8 w-8 rounded-full hover:bg-gray-200/50">
            <X className="h-4 w-4 text-gray-500" />
          </Button>
        </div>

        <div className="p-6 space-y-6">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-8 text-gray-500">
              <Loader2 className="h-8 w-8 animate-spin mb-2 text-blue-600" />
              <p className="text-sm">Loading topics...</p>
            </div>
          ) : topics.length === 0 ? (
            <div className="text-center py-6 text-gray-500">
              <p>No topics found for this event.</p>
              <p className="text-sm mt-1">Please create a topic first.</p>
            </div>
          ) : (
            <>
              <div className="space-y-2">
                <Label htmlFor="topic">Select Topic</Label>
                <Select 
                    id="topic"
                    value={selectedTopicId} 
                    onChange={(e) => setSelectedTopicId(e.target.value)}
                    className="w-full"
                >
                    <option value="" disabled>Choose a topic...</option>
                    {topics.map((topic) => (
                      <option key={topic.id} value={topic.id.toString()}>
                        {topic.title}
                      </option>
                    ))}
                </Select>
              </div>

              <div className="space-y-4">
                <div className="flex justify-between items-center">
                    <Label>Number of Rounds</Label>
                    <span className="text-sm font-bold text-blue-600">{roundCount} Rounds</span>
                </div>
                
                <div className="relative pt-2 pb-2 px-1">
                    {/* Track Background */}
                    <div className="absolute top-[14px] left-0 w-full h-1.5 bg-gray-100 rounded-full"></div>
                    
                    {/* Filled Track */}
                    <div 
                        className="absolute top-[14px] left-0 h-1.5 bg-blue-600 rounded-full transition-all duration-300"
                        style={{ width: `${((parseInt(roundCount) - 2) / 4) * 100}%` }}
                    ></div>

                    {/* Steps */}
                    <div className="relative flex justify-between w-full">
                        {[2, 3, 4, 5, 6].map((num) => (
                            <div 
                                key={num} 
                                className="flex flex-col items-center gap-2 cursor-pointer group"
                                onClick={() => setRoundCount(num.toString())}
                            >
                                <div className={`w-3.5 h-3.5 rounded-full border-2 transition-all duration-200 z-10 ${
                                    parseInt(roundCount) >= num 
                                        ? 'bg-blue-600 border-blue-600 scale-110' 
                                        : 'bg-white border-gray-300 group-hover:border-blue-400'
                                }`}></div>
                                <span className={`text-xs font-medium transition-colors ${
                                    parseInt(roundCount) === num ? 'text-blue-600' : 'text-gray-400'
                                }`}>{num}</span>
                            </div>
                        ))}
                    </div>
                </div>
                
                <p className="text-xs text-gray-500 text-center pt-2">
                  Standard 6-3-5 method uses 6 rounds.
                </p>
              </div>
            </>
          )}
        </div>

        <div className="p-4 border-t border-gray-100 bg-gray-50/50 flex justify-end gap-3">
          <Button variant="outline" onClick={onClose} disabled={submitting}>
            Cancel
          </Button>
          <Button
            onClick={handleStart}
            disabled={submitting || loading || topics.length === 0 || !selectedTopicId || !teamId}
            className="bg-blue-600 hover:bg-blue-700 text-white"
          >
            {submitting ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" /> Starting...
              </>
            ) : (
              <>
                <Play className="mr-2 h-4 w-4" /> Start Session
              </>
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}
