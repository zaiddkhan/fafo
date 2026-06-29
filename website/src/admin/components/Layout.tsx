import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "@admin/auth/AuthProvider";
import { cn } from "./ui";

const NAV = [
  { to: "/admin/creators", label: "Creator Queue" },
  { to: "/admin/quests", label: "Quest Manager" },
  { to: "/admin/seeding", label: "Event Seeding" },
  { to: "/admin/density", label: "Density View" },
  { to: "/admin/users", label: "User Management" },
  { to: "/admin/notifications", label: "Notifications" },
  { to: "/admin/analytics", label: "Analytics" },
];

export function Layout() {
  const { user, logout } = useAuth();
  return (
    <div className="flex h-screen overflow-hidden">
      <aside className="flex h-screen w-64 flex-shrink-0 flex-col border-r-[2.5px] border-ink bg-cream">
        <div className="flex items-center gap-2 border-b-[2.5px] border-ink px-5 py-5">
          <span className="grid h-9 w-9 place-items-center rounded-lg border-2 border-ink bg-brand-500 text-base font-extrabold text-white shadow-[2px_2px_0_0_#16171b]">
            F
          </span>
          <span className="text-lg font-extrabold tracking-tight">
            Fafo Admin
          </span>
        </div>
        <nav className="flex-1 space-y-1.5 px-3 py-4">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                cn(
                  "block rounded-xl border-2 px-3 py-2 text-sm font-bold transition-all",
                  isActive
                    ? "border-ink bg-brand-500 text-white shadow-[3px_3px_0_0_#16171b]"
                    : "border-transparent text-ink/70 hover:bg-black/[0.04] hover:text-ink",
                )
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="border-t-[2.5px] border-ink px-5 py-4">
          <div className="truncate text-xs font-semibold text-ink/50">
            {user?.email}
          </div>
          <button
            onClick={logout}
            className="mt-1.5 text-sm font-bold text-ink hover:text-brand-600"
          >
            Sign out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-y-auto">
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
    <div className="mb-6 flex items-start justify-between gap-4">
      <div>
        <h1 className="text-2xl font-extrabold tracking-tight text-ink">
          {title}
        </h1>
        {subtitle && (
          <p className="mt-1 max-w-2xl text-sm font-medium text-ink/60">
            {subtitle}
          </p>
        )}
      </div>
      {action}
    </div>
  );
}
