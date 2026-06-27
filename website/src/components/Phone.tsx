import type { ReactNode } from 'react'

export function Phone({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`phone ${className}`}>
      <div className="screen">
        <div className="statusbar">
          <span>9:41</span>
          <span className="sb-r">5G ▦ 100%</span>
        </div>
        {children}
      </div>
    </div>
  )
}
