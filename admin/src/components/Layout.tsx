import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "@/auth/AuthProvider";
import { cn } from "./ui";

const NAV = [
  { to: "/creators", label: "Creator Queue" },
  { to: "/quests", label: "Quest Manager" },
  { to: "/seeding", label: "Event Seeding" },
  { to: "/density", label: "Density View" },
  { to: "/users", label: "User Management" },
  { to: "/notifications", label: "Notifications" },
  { to: "/analytics", label: "Analytics" },
];

export function Layout() {
  const { user, logout } = useAuth();
  return (
    <div className="flex min-h-full">
      <aside className="flex w-60 flex-shrink-0 flex-col bg-brand-700 text-white">
        <div className="px-5 py-5 text-lg font-extrabold tracking-tight">
          Fafo Admin
        </div>
        <nav className="flex-1 space-y-1 px-3">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                cn(
                  "block rounded-lg px-3 py-2 text-sm font-semibold transition-colors",
                  isActive
                    ? "bg-white/15 text-white"
                    : "text-white/75 hover:bg-white/10 hover:text-white",
                )
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="border-t border-white/10 px-5 py-4 text-xs">
          <div className="truncate text-white/60">{user?.email}</div>
          <button
            onClick={logout}
            className="mt-2 font-semibold text-white/90 hover:text-white"
          >
            Sign out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto">
        <div className="mx-auto max-w-6xl px-8 py-8">
          <Outlet />
        </div>
      </main>
    </div>
  );
}

export function PageHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="mb-6 flex items-start justify-between">
      <div>
        <h1 className="text-2xl font-extrabold text-gray-900">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-gray-500">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}
