import Link from "next/link"
import { MonitorSmartphone } from "lucide-react"

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="grid h-screen w-full lg:grid-cols-2 bg-background text-foreground">
      <div className="relative hidden h-full flex-col bg-muted p-10 text-white lg:flex dark:border-r">
        <div className="absolute inset-0 bg-[#003cff]/80 mix-blend-multiply transition-all" /> {/* Overlay for blue tint */}
        {/* Placeholder for the background image - using a nice gradient/colored div for now or an image if available */}
        <div className="absolute inset-0 bg-center bg-cover -z-10" style={{ backgroundColor: '#1e3a8a' }}></div>
        
        <div className="relative z-20 flex items-center text-lg font-medium">
          <MonitorSmartphone className="mr-2 h-6 w-6" />
          BrainstormApp
        </div>
        <div className="relative z-20 mt-auto">
          <h1 className="text-4xl font-bold tracking-tight mb-4">Unlock Your Team's True Potential</h1>
          <p className="text-lg text-slate-200">
            Join thousands of forward-thinking teams who use BrainstormApp to turn chaotic ideas into structured innovation.
          </p>
          
          <div className="mt-8 flex gap-2">
            <div className="h-1 w-8 rounded-full bg-blue-500"></div>
            <div className="h-1 w-8 rounded-full bg-gray-600"></div>
            <div className="h-1 w-8 rounded-full bg-gray-600"></div>
          </div>
          
          <div className="mt-10 text-sm text-slate-400">
            © 2024 BrainstormApp Inc.
          </div>
        </div>
      </div>
      <div className="p-6 lg:p-8 flex items-center justify-center h-full w-full bg-[#f8fafc]">
        {children}
      </div>
    </div>
  )
}
