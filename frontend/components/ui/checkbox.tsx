import * as React from "react"
import { Check } from "lucide-react"

import { cn } from "@/lib/utils"

const Checkbox = React.forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(
  ({ className, ...props }, ref) => {
    return (
        <div className="flex items-center space-x-2">
            <div className="relative flex items-center">
                <input
                type="checkbox"
                className={cn(
                    "peer h-4 w-4 shrink-0 rounded-sm border border-gray-300 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 appearance-none checked:bg-blue-600 checked:border-blue-600",
                    className
                )}
                ref={ref}
                {...props}
                />
                 <Check className="absolute pointer-events-none opacity-0 peer-checked:opacity-100 text-white w-3 h-3 left-0.5 top-0.5" strokeWidth={3} />
            </div>
      </div>
    )
  }
)
Checkbox.displayName = "Checkbox"

export { Checkbox }
