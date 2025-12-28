"use client";

import { Navbar } from "@/components/dashboard/Navbar";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-gray-50/50">
      <Navbar />

      {/* Main Content */}
      <main className="p-6 md:p-8 max-w-7xl mx-auto">
        {children}
      </main>
    </div>
  );
}
