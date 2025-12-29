"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { Loader2 } from "lucide-react";

const PUBLIC_PATHS = ["/login", "/signup"];

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const checkAuth = () => {
      const token = localStorage.getItem("token");
      const isPublicPath = PUBLIC_PATHS.includes(pathname);

      if (!token) {
        // Not logged in
        if (!isPublicPath) {
          // Redirect to login if trying to access protected route
          router.push("/login");
          return;
        }
      } else {
        // Logged in
        if (isPublicPath) {
          // Redirect to dashboard if trying to access public route while logged in
          router.push("/");
          return;
        }

        // Restrict TEAM_MEMBER from accessing /dashboard paths
        if (pathname.startsWith("/dashboard")) {
            const userStr = localStorage.getItem("user");
            if (userStr) {
                try {
                    const user = JSON.parse(userStr);
                    const role = user.role;
                    
                    // Team Members cannot access any dashboard
                    if (role === "TEAM_MEMBER" || role === "ROLE_TEAM_MEMBER") {
                        router.push("/"); 
                        return;
                    }

                    // Team Leaders cannot access the main dashboard overview, only sub-pages like /events
                    if ((role === "TEAM_LEADER" || role === "ROLE_TEAM_LEADER") && (pathname === "/dashboard" || pathname.startsWith("/dashboard/topics"))) {
                        router.push("/dashboard/events");
                        return;
                    }
                } catch (e) {
                    console.error("Error parsing user for auth guard check", e);
                }
            }
        }
      }
      
      // If we are here, access is allowed
      setIsLoading(false);
    };

    // Check auth on mount and path change
    checkAuth();
  }, [pathname, router]);

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return <>{children}</>;
}
