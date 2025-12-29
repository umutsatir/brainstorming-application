"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { 
    LogOut, 
    LayoutDashboard, 
    Users, 
    Calendar, 
    Crown, 
    ArrowRight, 
    Zap, 
    Target,
    Shield,
    Sparkles
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import Link from "next/link";
import { Session } from "@/types/session";

interface Team {
    id: number;
    name: string;
    focus: string;
    leader_name: string;
    event_id: number;
    member_count: number;
}

interface Event {
    id: number;
    name: string;
    description: string;
    start_date: string;
    end_date: string;
}

interface TeamMember {
    id: number;
    full_name: string;
    email: string;
    role: string;
    is_team_leader: boolean;
}

export default function Home() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [team, setTeam] = useState<Team | null>(null);
  const [event, setEvent] = useState<Event | null>(null);
  const [members, setMembers] = useState<TeamMember[]>([]);
  const [activeSession, setActiveSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  // Helper to get initials safely
  const getInitials = (name?: string) => {
      return (name || "?").charAt(0).toUpperCase();
  };

  // Helper to get display name safely
  const getDisplayName = (member: TeamMember) => {
      return member.full_name || member.email || "Unknown Member";
  };
  
  // Helper to get first name for welcome message
  const getUserFirstName = () => {
      if (!user?.fullName) return "User";
      return user.fullName.split(" ")[0];
  };

  useEffect(() => {
     const userStr = localStorage.getItem("user");
     if (userStr) {
         try {
             const parsedUser = JSON.parse(userStr);
             setUser(parsedUser);
             // Fetch team info for ALL users
             fetchTeamInfo();
         } catch (e) {
             console.error("Failed to parse user", e);
             setLoading(false);
         }
     } else {
         router.push("/login");
     }
  }, []);

  const getEventStatus = (evt: Event) => {
      const now = new Date();
      const sDate = evt.start_date;
      const eDate = evt.end_date;

      if (!sDate || !eDate) return "ACTIVE"; // Fallback if dates are missing

      const start = new Date(sDate);
      const end = new Date(eDate);
      
      // Reset time parts for date-only comparison if needed, but simple comparison works
      if (now >= start && now <= end) return "ACTIVE";
      if (now < start) return "UPCOMING";
      return "PAST";
  };

  const fetchTeamInfo = async () => {
      try {
          // 1. Fetch User's Teams
          const teamsRes = await api.get('/teams/my-teams');
          const teams = teamsRes.data;
          
          if (teams && teams.length > 0) {
              let selectedTeam = teams[0];
              let selectedEvent: Event | null = null;
              
              // If multiple teams, find the "best" one (Active > Upcoming > Past)
              if (teams.length > 0) {
                  const teamsWithEvents = await Promise.all(teams.map(async (t: Team) => {
                      const eId = t.event_id;
                      if (!eId) {
                          console.warn("No event ID found for team:", t);
                          return { team: t, event: null, status: "NONE" };
                      }
                      try {
                          const eRes = await api.get(`/events/${eId}`);
                          const evt = eRes.data;
                          return { team: t, event: evt, status: getEventStatus(evt) };
                      } catch (e) {
                          console.error("Failed to fetch event:", e);
                          return { team: t, event: null, status: "NONE" };
                      }
                  }));

                  // Priority: ACTIVE > UPCOMING > PAST > NONE
                  const priority = { "ACTIVE": 3, "UPCOMING": 2, "PAST": 1, "NONE": 0 };
                  
                  // Sort by priority descending
                  teamsWithEvents.sort((a, b) => {
                      // @ts-ignore
                      return priority[b.status] - priority[a.status];
                  });

                  const bestMatch = teamsWithEvents[0];
                  if (bestMatch.team) {
                      selectedTeam = bestMatch.team;
                      selectedEvent = bestMatch.event;
                  }
              }

              setTeam(selectedTeam);
              if (selectedEvent) {
                  setEvent(selectedEvent);
              }

              // 3. Fetch Team Members
              if (selectedTeam) {
                   const membersRes = await api.get(`/teams/${selectedTeam.id}/members`);
                   setMembers(membersRes.data);
                   
                   // 4. Fetch Active Sessions
                   const sessionsRes = await api.get(`/teams/${selectedTeam.id}/sessions?status=RUNNING`);
                   if (sessionsRes.data && sessionsRes.data.length > 0) {
                       setActiveSession(sessionsRes.data[0]);
                   }
              }
          }
      } catch (error) {
          console.error("Failed to fetch team info", error);
      } finally {
          setLoading(false);
      }
  };


  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    router.push("/login");
  };

  if (loading) {
      return (
          <div className="min-h-screen flex items-center justify-center bg-gray-50">
              <div className="relative flex flex-col items-center">
                   <div className="relative h-16 w-16 bg-white rounded-2xl flex items-center justify-center border border-gray-100 shadow-xl mb-6">
                       <Sparkles className="h-8 w-8 text-blue-600 animate-pulse" />
                   </div>
                   <div className="h-2 w-32 bg-gray-200 rounded-full overflow-hidden">
                       <div className="h-full bg-blue-600 animate-[loading_1s_ease-in-out_infinite] w-1/2"></div>
                   </div>
              </div>
          </div>
      );
  }

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900 overflow-x-hidden relative">
       {/* Background Decoration */}
       <div className="fixed top-0 left-0 w-full h-[500px] bg-gradient-to-b from-blue-50 to-transparent pointer-events-none z-0"></div>

       <div className="max-w-6xl mx-auto p-6 md:p-8 relative z-10">
          
          {/* Header Section */}
          <div className="flex flex-col md:flex-row justify-between items-center gap-6 mb-12">
              <div className="flex items-center gap-5">
                  <div className="h-14 w-14 bg-white rounded-2xl flex items-center justify-center shadow-lg shadow-blue-100 border border-blue-50 transform hover:scale-105 transition-transform duration-300">
                      <LayoutDashboard className="h-7 w-7 text-blue-600" />
                  </div>
                  <div>
                      <h1 className="text-3xl font-bold text-gray-900 tracking-tight flex items-center gap-2">
                        Welcome Back, {getUserFirstName()} 
                        <span className="hidden sm:inline-block animate-wave">👋</span>
                      </h1>
                      <p className="text-gray-500 font-medium">Ready to innovate today?</p>
                  </div>
              </div>
              
              <Button 
                variant="outline" 
                className="bg-white hover:bg-gray-50 text-gray-600 border-gray-200 hover:text-red-600 hover:border-red-100 transition-all rounded-full px-6 shadow-sm"
                onClick={handleLogout}
              >
                <LogOut className="mr-2 h-4 w-4" />
                Sign Out
              </Button>
          </div>

          {/* Main Content */}
          {team ? (
              <div className="space-y-8">
                  {/* Active Session Section */}
                  <div className="w-full bg-white rounded-3xl p-1 shadow-xl shadow-blue-100 border border-blue-100 animate-fade-in-up">
                      <div className={`rounded-[20px] p-8 md:p-10 flex flex-col md:flex-row items-center justify-between gap-8 h-full relative overflow-hidden transition-all duration-500 ${
                          activeSession 
                          ? "bg-gradient-to-br from-blue-600 to-indigo-700 text-white" 
                          : "bg-white text-gray-900"
                      }`}>
                          {/* Background Pattern for Active */}
                          {activeSession && (
                              <>
                                  <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none"></div>
                                  <div className="absolute bottom-0 left-0 w-64 h-64 bg-indigo-500/20 rounded-full blur-3xl -ml-16 -mb-16 pointer-events-none"></div>
                              </>
                          )}

                          <div className="space-y-4 max-w-2xl relative z-10">
                              <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider backdrop-blur-sm transition-colors ${
                                  activeSession
                                  ? "bg-white/20 text-white"
                                  : "bg-gray-100 text-gray-500"
                              }`}>
                                  {activeSession ? <Zap className="h-3 w-3 fill-current" /> : <Calendar className="h-3 w-3" />} 
                                  {activeSession ? "Live Session" : "Session Status"}
                              </div>
                              
                              <h2 className={`text-3xl md:text-4xl font-bold leading-tight ${activeSession ? "text-white" : "text-gray-900"}`}>
                                  {activeSession ? (
                                      <>
                                          Brainstorming in Progress: <br/>
                                          <span className="text-blue-200">
                                              {activeSession.topic_title || "Untitled Topic"}
                                          </span>
                                      </>
                                  ) : (
                                    "No Active Session"
                                  )}
                              </h2>
                              
                              <p className={`text-lg ${activeSession ? "text-blue-100" : "text-gray-500"}`}>
                                  {activeSession 
                                      ? "Your team is currently brainstorming. Join now to contribute your ideas before the round ends!" 
                                      : "Waiting for the team leader to start a new brainstorming session. When it starts, it will appear here."}
                              </p>
                          </div>

                          {activeSession ? (
                              <Link href={`/session/${activeSession.id}`} className="flex-shrink-0 relative z-10">
                                  <Button className="h-14 px-8 bg-white text-blue-600 hover:bg-blue-50 font-bold text-lg rounded-xl shadow-lg transition-all hover:shadow-xl hover:-translate-y-1 border-0">
                                      Join Session <ArrowRight className="ml-2 h-5 w-5" />
                                  </Button>
                              </Link>
                          ) : (
                              <div className="h-16 w-16 rounded-full bg-gray-50 flex items-center justify-center text-gray-300">
                                  <Zap className="h-8 w-8 text-gray-300" />
                              </div>
                          )}
                      </div>
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                      
                      {/* Left Col: Team & Event Stats */}
                      <div className="lg:col-span-8 space-y-6">
                          
                          {/* Team Details Card */}
                          <div className="bg-white border border-gray-100 rounded-3xl p-8 shadow-md shadow-gray-200/50 hover:shadow-lg hover:shadow-gray-200/50 transition-all group">
                              <div className="flex items-start justify-between mb-8">
                                  <div>
                                      <h2 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-2">Team Overview</h2>
                                      <h3 className="text-3xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">{team.name}</h3>
                                  </div>
                                  <div className="h-12 w-12 bg-blue-50 rounded-2xl flex items-center justify-center text-blue-600 group-hover:bg-blue-600 group-hover:text-white transition-all">
                                      <Shield className="h-6 w-6" />
                                  </div>
                              </div>

                              <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                                  <div className="bg-gray-50 rounded-2xl p-5 border border-gray-100">
                                      <div className="flex items-center gap-3 mb-2">
                                          <Target className="h-5 w-5 text-emerald-500" />
                                          <span className="text-sm text-gray-500">Current Focus</span>
                                      </div>
                                      <p className="text-lg font-semibold text-gray-900">{team.focus}</p>
                                  </div>
                                  
                                  <div className="bg-gray-50 rounded-2xl p-5 border border-gray-100">
                                      <div className="flex items-center gap-3 mb-2">
                                          <Crown className="h-5 w-5 text-amber-500" />
                                          <span className="text-sm text-gray-500">Team Leader</span>
                                      </div>
                                      <p className="text-lg font-semibold text-gray-900">{team.leader_name}</p>
                                  </div>

                                  <div className="bg-gray-50 rounded-2xl p-5 border border-gray-100">
                                      <div className="flex items-center gap-3 mb-2">
                                          <Users className="h-5 w-5 text-violet-500" />
                                          <span className="text-sm text-gray-500">Members</span>
                                      </div>
                                      <p className="text-lg font-semibold text-gray-900">{members.length} Active</p>
                                  </div>
                              </div>
                          </div>

                          {/* Event Details Card */}
                          <div className="bg-white border border-gray-100 rounded-3xl p-8 shadow-md shadow-gray-200/50 hover:shadow-lg hover:shadow-gray-200/50 transition-all">
                              <div className="flex items-center gap-4 mb-6">
                                  <div className="h-10 w-10 bg-indigo-50 rounded-xl flex items-center justify-center text-indigo-600">
                                      <Calendar className="h-5 w-5" />
                                  </div>
                                  <div>
                                      <h2 className="text-xl font-bold text-gray-900">Current Event</h2>
                                  </div>
                                  {event && (
                                      <span className={`ml-auto px-3 py-1 rounded-full text-xs font-bold border ${
                                          getEventStatus(event) === "ACTIVE" 
                                          ? "bg-emerald-50 text-emerald-600 border-emerald-200"
                                          : getEventStatus(event) === "UPCOMING"
                                          ? "bg-blue-50 text-blue-600 border-blue-200"
                                          : "bg-gray-50 text-gray-500 border-gray-200"
                                      }`}>
                                          {getEventStatus(event)}
                                      </span>
                                  )}
                              </div>
                              
                              {event ? (
                                  <div className="space-y-4">
                                      <div>
                                          <h3 className="text-2xl font-bold text-gray-900 mb-2">{event.name}</h3>
                                          <p className="text-gray-500 leading-relaxed max-w-2xl">{event.description}</p>
                                      </div>
                                      <div className="flex items-center gap-4 text-sm text-gray-500 mt-4 pt-4 border-t border-gray-100">
                                          <span className="flex items-center gap-1"><Calendar className="h-4 w-4"/> Start: {event.start_date}</span>
                                          <span>•</span>
                                          <span className="flex items-center gap-1"><Calendar className="h-4 w-4"/> End: {event.end_date}</span>
                                      </div>
                                  </div>
                              ) : (
                                  <div className="text-center py-8 text-gray-500 bg-gray-50 rounded-2xl border border-dashed border-gray-200">
                                      <p>No active event details found.</p>
                                  </div>
                              )}
                          </div>
                      </div>

                      {/* Right Col: Members List */}
                      <div className="lg:col-span-4 max-h-[600px] flex flex-col">
                          <div className="bg-white border border-gray-100 rounded-3xl p-6 h-full shadow-md shadow-gray-200/50 flex flex-col">
                              <div className="flex items-center justify-between mb-6">
                                  <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                                      Team Roster
                                  </h2>
                                  <span className="bg-gray-100 text-gray-600 px-2 py-1 rounded-md text-xs font-bold">
                                      {members.length}
                                  </span>
                              </div>
                              
                              <div className="space-y-3 overflow-y-auto pr-2 custom-scrollbar flex-1">
                                  {members.map((member) => (
                                      <div key={member.id} className="group p-3 rounded-2xl bg-gray-50 border border-gray-100 hover:bg-white hover:shadow-md transition-all flex items-center justify-between">
                                          <div className="flex items-center gap-4">
                                              <div className={`h-10 w-10 rounded-full flex items-center justify-center text-sm font-bold shadow-sm ${
                                                  member.is_team_leader || member.isTeamLeader
                                                      ? "bg-gradient-to-br from-amber-400 to-orange-500 text-white" 
                                                      : "bg-white border border-gray-200 text-gray-600"
                                              }`}>
                                                  {getInitials(member.full_name)}
                                              </div>
                                              <div>
                                                  <p className="font-semibold text-gray-900">{getDisplayName(member)}</p>
                                                  <p className="text-xs text-gray-500">{
                                                        (member.role === "TEAM_LEADER" || member.is_team_leader) 
                                                        ? "Team Leader" : "Member"
                                                   }</p>
                                              </div>
                                          </div>
                                          {(member.is_team_leader || member.isTeamLeader) && (
                                              <Crown className="h-4 w-4 text-amber-500" />
                                          )}
                                      </div>
                                  ))}
                              </div>
                          </div>
                      </div>

                  </div>
              </div>
          ) : user?.role === "EVENT_MANAGER" || user?.role === "ROLE_EVENT_MANAGER" ? (
             // Special view for managers who are NOT in a team (which is default)
             <div className="max-w-md mx-auto mt-20 bg-white border border-gray-200 rounded-3xl p-10 text-center space-y-8 shadow-xl shadow-gray-200/50">
                 <div className="mx-auto h-20 w-20 bg-blue-50 text-blue-600 rounded-3xl flex items-center justify-center shadow-inner">
                    <LayoutDashboard className="h-9 w-9" />
                 </div>
                 
                 <div>
                   <h1 className="text-3xl font-bold text-gray-900">Manager Dashboard</h1>
                   <p className="text-gray-500 mt-2">Access your administrative tools below.</p>
                 </div>
  
                 <Link href="/dashboard/teams" className="w-full block">
                    <Button className="w-full bg-blue-600 hover:bg-blue-700 text-white h-12 text-md font-medium rounded-xl transition-transform active:scale-95 shadow-lg shadow-blue-600/20">
                       Go to Team Management <ArrowRight className="ml-2 h-4 w-4" />
                    </Button>
                 </Link>
              </div>
          ) : (
                // Fallback for anyone else without a team
                <div className="flex flex-col items-center justify-center h-[60vh] text-center space-y-6">
                    <div className="relative">
                        <div className="absolute inset-0 bg-blue-100 blur-3xl rounded-full opacity-50"></div>
                        <div className="relative h-24 w-24 bg-white rounded-[2rem] flex items-center justify-center border border-gray-200 shadow-xl text-gray-400">
                            <Users className="h-10 w-10" />
                        </div>
                    </div>
                    <div>
                        <h2 className="text-2xl font-bold text-gray-900">No Team Assigned</h2>
                        <p className="text-gray-500 mt-2 max-w-md mx-auto">
                            You are not currently assigned to any team in an active event. 
                            <br/>Please contact an event manager to get started.
                        </p>
                    </div>
                </div>
          )}
       </div>
       
       {/* CSS for custom scrollbar */}
       <style jsx global>{`
         .custom-scrollbar::-webkit-scrollbar {
           width: 6px;
           height: 6px;
         }
         .custom-scrollbar::-webkit-scrollbar-track {
           background: transparent;
         }
         .custom-scrollbar::-webkit-scrollbar-thumb {
           background: #e2e8f0;
           border-radius: 20px;
         }
         .custom-scrollbar::-webkit-scrollbar-thumb:hover {
           background: #cbd5e1;
         }
         @keyframes wave {
            0% { transform: rotate(0deg); }
            10% { transform: rotate(14deg); }
            20% { transform: rotate(-8deg); }
            30% { transform: rotate(14deg); }
            40% { transform: rotate(-4deg); }
            50% { transform: rotate(10deg); }
            60% { transform: rotate(0deg); }
            100% { transform: rotate(0deg); }
         }
         .animate-wave {
            animation: wave 2.5s infinite;
            transform-origin: 70% 70%;
         }
         @keyframes loading {
            0% { transform: translateX(-100%); }
            100% { transform: translateX(200%); }
         }
         @keyframes fade-in-up {
            0% { opacity: 0; transform: translateY(20px); }
            100% { opacity: 1; transform: translateY(0); }
         }
         .animate-fade-in-up {
            animation: fade-in-up 0.6s ease-out forwards;
         }
       `}</style>
    </div>
  );
}
