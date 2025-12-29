"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutDashboard, Calendar, Users, Settings, Bell, Search, User, MessageSquare } from "lucide-react";
import { Button } from "@/components/ui/button";

export function Navbar() {
  const pathname = usePathname();

  const navigation = [
    { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
    { name: "Events", href: "/dashboard/events", icon: Calendar },
    { name: "Topics", href: "/dashboard/topics", icon: MessageSquare },
    { name: "Settings", href: "/dashboard/settings", icon: Settings },
  ];

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center border-b border-gray-200/40 bg-white/70 backdrop-blur-xl px-6 supports-[backdrop-filter]:bg-white/60">
      <Link href="/" className="flex items-center gap-2 font-bold text-xl mr-8 text-blue-600 hover:opacity-80 transition-opacity">
        <div className="bg-gradient-to-tr from-blue-600 to-indigo-600 text-white p-1.5 rounded-lg shadow-lg shadow-blue-500/20">
          <LayoutDashboard className="h-5 w-5" />
        </div>
        <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-700 to-indigo-700">BrainstormApp</span>
      </Link>

      <nav className="hidden md:flex items-center gap-1">
        {navigation.map((item) => {
          const isActive = pathname.startsWith(item.href) && (item.href !== '/dashboard' || pathname === '/dashboard');
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
                isActive 
                  ? "bg-blue-50 text-blue-700 shadow-sm shadow-blue-100" 
                  : "text-gray-500 hover:text-gray-900 hover:bg-gray-100/50"
              }`}
            >
              <item.icon className={`h-4 w-4 ${isActive ? "text-blue-600" : "text-gray-400"}`} />
              {item.name}
            </Link>
          );
        })}
      </nav>

      <div className="ml-auto flex items-center gap-4">
        <div className="relative hidden sm:block w-64 group">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 group-focus-within:text-blue-500 transition-colors" />
          <input
            className="w-full rounded-full border border-gray-200 bg-gray-50/50 py-2 pl-10 pr-4 text-sm outline-none transition-all placeholder:text-gray-400 focus:border-blue-200 focus:bg-white focus:ring-4 focus:ring-blue-50"
            placeholder="Search..."
            type="search"
          />
        </div>
        
        <div className="flex items-center gap-2 pl-2 border-l border-gray-200/60">
            <Button variant="ghost" size="icon" className="text-gray-500 hover:text-gray-700 hover:bg-gray-100/50 rounded-full">
              <Bell className="h-5 w-5" />
            </Button>
            
            <div className="h-9 w-9 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white shadow-md shadow-blue-500/20 cursor-pointer hover:shadow-lg transition-shadow">
              <User className="h-4 w-4" />
            </div>
        </div>
      </div>
    </header>
  );
}
