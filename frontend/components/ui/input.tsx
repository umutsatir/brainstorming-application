import * as React from "react"

import { cn } from "@/lib/utils"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
    icon?: React.ReactNode
  }

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, icon, ...props }, ref) => {
    return (
      <div className="relative w-full">
        {icon && (
          <div className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground/50">
            {icon}
          </div>
        )}
        <input
          type={type}
          className={cn(
            "flex h-12 w-full rounded-xl border border-gray-200 bg-white/50 px-4 py-1 text-base shadow-sm transition-all focus-visible:border-blue-500 focus-visible:ring-4 focus-visible:ring-blue-500/10 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm",
            icon ? "pl-10" : "", // Add padding if icon exists
            className
          )}
          ref={ref}
          {...props}
        />
      </div>
    )
  }
)
Input.displayName = "Input"

export { Input }
