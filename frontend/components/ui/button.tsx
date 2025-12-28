import * as React from "react"

import { cn } from "@/lib/utils"

// Since I didn't install class-variance-authority (cva) which is common in shadcn, 
// I will implement a simpler version using standard props or just install cva if I want to be fancy.
// For now, I'll stick to a simple implementation with clsx/tailwind-merge as planned.

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  asChild?: boolean
  variant?: "default" | "outline" | "ghost" | "link"
  size?: "default" | "sm" | "lg" | "icon"
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "default", size = "default", asChild = false, ...props }, ref) => {
    // If we had @radix-ui/react-slot we could use basic polymorphism, but I didn't install it.
    // I will remove Slot usage for now to keep dependencies light as per plan, unless I really need it.
    // Actually, let's just use standard button.
    
    const Comp = "button"
    
    const baseStyles = "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0"
    
    const variants = {
      default: "bg-[#1d4ed8] text-white shadow hover:bg-[#1d4ed8]/90", // Blue color from design roughly
      outline: "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
      ghost: "hover:bg-accent hover:text-accent-foreground",
      link: "text-primary underline-offset-4 hover:underline",
    }
    
    const sizes = {
      default: "h-11 px-8 py-2", // Taller buttons as per design
      sm: "h-8 rounded-md px-3 text-xs",
      lg: "h-12 rounded-md px-8",
      icon: "h-9 w-9",
    }

    return (
      <Comp
        className={cn(baseStyles, variants[variant], sizes[size], className)}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button }
