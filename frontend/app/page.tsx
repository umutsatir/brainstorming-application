"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, useEffect } from "react";
import { LogOut, ArrowRight, LayoutDashboard } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function Home() {
  const router = useRouter();
  const [userRole, setUserRole] = useState<string | null>(null);

  useEffect(() => {
     // Get user role
     const userStr = localStorage.getItem("user");
     if (userStr) {
         try {
             const user = JSON.parse(userStr);
             setUserRole(user.role);
         } catch (e) {}
     }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    router.push("/login");
  };

  const isTeamMember = userRole === "TEAM_MEMBER" || userRole === "ROLE_TEAM_MEMBER";

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gray-50 p-6">
       <div className="max-w-md w-full bg-white rounded-xl shadow-lg p-8 text-center space-y-6">
          <div className="mx-auto h-16 w-16 bg-blue-100 rounded-full flex items-center justify-center text-blue-600">
              <LayoutDashboard className="h-8 w-8" />
          </div>
          
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Welcome Back!</h1>
            <p className="text-gray-500 mt-2">You are successfully logged in.</p>
          </div>

          <div className="grid gap-3">
             {!isTeamMember && (
                 <Link href="/dashboard/teams" className="w-full">
                    <Button className="w-full bg-blue-600 hover:bg-blue-700 h-11" size="lg">
                       Go to Team Management <ArrowRight className="ml-2 h-4 w-4" />
                    </Button>
                 </Link>
             )}

             {isTeamMember && (
                 <div className="p-4 bg-yellow-50 text-yellow-800 text-sm rounded-lg border border-yellow-100">
                    You are logged in as a Team Member. Dashboard access is restricted.
                 </div>
             )}
             
             <Button 
                variant="outline" 
                className="w-full h-11 border-gray-200 text-gray-600 hover:bg-gray-50 hover:text-red-600 hover:border-red-200 transition-colors"
                onClick={handleLogout}
              >
                <LogOut className="mr-2 h-4 w-4" />
                Sign Out
             </Button>
          </div>
       </div>
    </div>
  );
}
