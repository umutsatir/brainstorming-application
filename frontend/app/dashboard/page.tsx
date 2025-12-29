"use client";

import React, { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { 
  Users, 
  Layers, 
  CheckCircle2, 
  Lightbulb, 
  MoreHorizontal, 
  ArrowUpRight,
  ArrowDownRight,
  MessageSquare,
  UserPlus,
  FileCheck,
  Loader2
} from "lucide-react";
import { api } from "@/lib/api";

// Types for our local state
interface DashboardState {
  stats: {
    totalParticipants: number;
    activeTeams: number;
    completedSessions: number;
    ideasGenerated: number;
  };
  activeTopics: any[];
  recentActivities: any[];
}

export default function DashboardPage() {
  const [data, setData] = useState<DashboardState | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch all data in parallel
        const [usersRes, teamsRes, sessionsRes, ideasRes] = await Promise.all([
          api.get('/users'),
          api.get('/teams'),
          api.get('/sessions'),
          api.get('/ideas')
        ]);

        const users = usersRes.data;
        const teams = teamsRes.data;
        const sessions = sessionsRes.data;
        const ideas = ideasRes.data;

        // Process Stats
        const stats = {
          totalParticipants: users.length,
          activeTeams: teams.length,
          completedSessions: sessions.filter((s: any) => s.status === 'COMPLETED').length,
          ideasGenerated: ideas.length
        };

        // Process Active Topics (Sessions that are RUNNING or PAUSED)
        const activeSessions = sessions.filter((s: any) => s.status === 'RUNNING' || s.status === 'PAUSED');
        const activeTopics = activeSessions.map((session: any) => {
          const progress = session.roundCount > 0 
            ? Math.round((session.currentRound / session.roundCount) * 100) 
            : 0;
            
          return {
            name: session.topicTitle || "Untitled Topic",
            teams: [session.teamName || "Unknown Team"],
            status: session.status === 'RUNNING' ? 'Active' : 'Paused',
            progress: progress
          };
        });

        // Process Recent Activity (Mocking from sessions/ideas for now as we don't have a global audit log endpoint)
        // We'll take the last 5 sessions/ideas and mix them
        const recentActivities = [];
        
        // Add recent sessions
        sessions.slice(0, 3).forEach((s: any) => {
           recentActivities.push({
             user: "System",
             action: s.status === 'COMPLETED' ? "completed session" : "updated session",
             target: s.topicTitle,
             message: `Round ${s.currentRound}/${s.roundCount}`,
             time: "Recently",
             type: s.status === 'COMPLETED' ? 'completion' : 'update',
             avatarColor: "bg-blue-100 text-blue-600"
           });
        });

        // Add recent ideas (if any)
        ideas.slice(0, 2).forEach((idea: any) => {
            recentActivities.push({
                user: "Team Member", // We might not have user name easily here without extra calls
                action: "submitted idea",
                target: "Brainstorming",
                message: idea.content ? idea.content.substring(0, 30) + "..." : "New idea",
                time: "Recently",
                type: "submission",
                avatarColor: "bg-purple-100 text-purple-600"
            });
        });

        setData({
          stats,
          activeTopics,
          recentActivities
        });

      } catch (err) {
        console.error("Failed to fetch dashboard data:", err);
        setError("Failed to load dashboard data. Please try again later.");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-[60vh] text-red-500">
        {error}
      </div>
    );
  }

  if (!data) return null;

  const statsDisplay = [
    {
      title: "Total Participants",
      value: data.stats.totalParticipants.toLocaleString(),
      change: "+12%", // Mock
      trend: "up",
      icon: Users,
    },
    {
      title: "Active Teams",
      value: data.stats.activeTeams.toLocaleString(),
      change: "-0%",
      trend: "neutral",
      icon: Layers,
    },
    {
      title: "Completed Sessions",
      value: data.stats.completedSessions.toLocaleString(),
      change: "+3",
      trend: "up",
      icon: CheckCircle2,
    },
    {
      title: "Ideas Generated",
      value: data.stats.ideasGenerated.toLocaleString(),
      change: "+8%",
      trend: "up",
      icon: Lightbulb,
    },
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-gray-900">Dashboard Overview</h1>
          <p className="text-gray-500 mt-1">Good morning, Alex. Here is what's happening today.</p>
        </div>
        <Button className="bg-blue-600 hover:bg-blue-700 text-white shadow-sm">
          + Start New Session
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {statsDisplay.map((stat, index) => (
          <div key={index} className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <p className="text-sm font-medium text-gray-500">{stat.title}</p>
              <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                stat.trend === 'up' ? 'bg-green-50 text-green-700' : 
                stat.trend === 'down' ? 'bg-red-50 text-red-700' : 
                'bg-gray-100 text-gray-600'
              }`}>
                {stat.trend === 'up' ? <ArrowUpRight className="w-3 h-3 mr-1" /> : 
                 stat.trend === 'down' ? <ArrowDownRight className="w-3 h-3 mr-1" /> : null}
                {stat.change}
              </span>
            </div>
            <div className="flex items-end justify-between">
              <h3 className="text-3xl font-bold text-gray-900">{stat.value}</h3>
              {/* Simple SVG Line Chart Simulation */}
              <svg className="w-16 h-8 text-blue-500" viewBox="0 0 64 32" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M0 28 C 10 28, 15 10, 25 15 C 35 20, 40 5, 64 10" vectorEffect="non-scaling-stroke" className="opacity-50" />
              </svg>
            </div>
          </div>
        ))}
      </div>

      <div className="grid gap-8 lg:grid-cols-3">
        {/* Active Topics */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-gray-100 flex justify-between items-center">
              <h2 className="text-lg font-semibold text-gray-900">Active Topics</h2>
              <Button variant="ghost" size="icon" className="text-gray-400 hover:text-gray-600">
                <MoreHorizontal className="w-5 h-5" />
              </Button>
            </div>
            <div className="p-0">
              <table className="w-full text-left text-sm">
                <thead className="bg-gray-50/50 text-gray-500 font-medium">
                  <tr>
                    <th className="px-6 py-4">TOPIC NAME</th>
                    <th className="px-6 py-4">TEAMS</th>
                    <th className="px-6 py-4">STATUS</th>
                    <th className="px-6 py-4">PROGRESS</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {data.activeTopics.length > 0 ? (
                    data.activeTopics.map((topic, i) => (
                      <tr key={i} className="hover:bg-gray-50/50 transition-colors">
                        <td className="px-6 py-4 font-medium text-gray-900">{topic.name}</td>
                        <td className="px-6 py-4">
                          <div className="flex -space-x-2">
                            {topic.teams.map((team: string, j: number) => (
                              <div key={j} className="w-8 h-8 rounded-full bg-indigo-100 border-2 border-white flex items-center justify-center text-xs font-bold text-indigo-600" title={team}>
                                {team.charAt(0)}
                              </div>
                            ))}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            topic.status === 'Active' ? 'bg-green-50 text-green-700' : 'bg-yellow-50 text-yellow-700'
                          }`}>
                            {topic.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 w-1/4">
                          <div className="flex items-center gap-3">
                            <span className="text-xs text-gray-500 w-8">{topic.progress}%</span>
                            <div className="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
                              <div 
                                className="h-full bg-blue-600 rounded-full" 
                                style={{ width: `${topic.progress}%` }}
                              />
                            </div>
                          </div>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={4} className="px-6 py-8 text-center text-gray-500">
                        No active topics found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
            <div className="p-4 border-t border-gray-100 bg-gray-50/30 text-center">
                <Button variant="link" className="text-blue-600 text-sm font-medium">View All Topics</Button>
            </div>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm h-full">
            <div className="p-6 border-b border-gray-100">
              <h2 className="text-lg font-semibold text-gray-900">Recent Activity</h2>
            </div>
            <div className="p-6 space-y-8">
              {data.recentActivities.length > 0 ? (
                data.recentActivities.map((activity, i) => (
                  <div key={i} className="flex gap-4">
                    <div className={`w-10 h-10 rounded-full flex-shrink-0 flex items-center justify-center ${activity.avatarColor}`}>
                      {activity.type === 'comment' && <MessageSquare className="w-5 h-5" />}
                      {activity.type === 'submission' && <Users className="w-5 h-5" />}
                      {activity.type === 'join' && <UserPlus className="w-5 h-5" />}
                      {activity.type === 'completion' && <CheckCircle2 className="w-5 h-5" />}
                      {activity.type === 'update' && <FileCheck className="w-5 h-5" />}
                    </div>
                    <div className="space-y-1">
                      <p className="text-sm text-gray-900">
                        <span className="font-semibold">{activity.user}</span> {activity.action} <span className="font-medium text-blue-600">{activity.target}</span>
                      </p>
                      {activity.message && (
                        <p className="text-sm text-gray-500 italic">
                          {activity.message}
                        </p>
                      )}
                      <p className="text-xs text-gray-400">{activity.time}</p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center text-gray-500 py-8">No recent activity.</div>
              )}
            </div>
            <div className="p-4 border-t border-gray-100 bg-gray-50/30 text-center">
                <Button variant="link" className="text-blue-600 text-sm font-medium">View All Activity</Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
