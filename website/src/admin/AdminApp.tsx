import { Navigate, Route, Routes } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider, useAuth } from "@admin/auth/AuthProvider";
import { LoginPage } from "@admin/auth/LoginPage";
import { Layout } from "@admin/components/Layout";
import { Button, Card, Spinner } from "@admin/components/ui";
import { initAnalytics } from "@admin/lib/analytics";
import { CreatorQueuePage } from "@admin/modules/creators/CreatorQueuePage";
import { QuestManagerPage } from "@admin/modules/quests/QuestManagerPage";
import { EventSeedingPage } from "@admin/modules/seeding/EventSeedingPage";
import { DensityViewPage } from "@admin/modules/density/DensityViewPage";
import { UserManagementPage } from "@admin/modules/users/UserManagementPage";
import { NotificationTemplatesPage } from "@admin/modules/notifications/NotificationTemplatesPage";
import "./admin.css";

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, refetchOnWindowFocus: false } },
});

initAnalytics();

function NotAuthorized() {
  const { user, logout } = useAuth();
  return (
    <div className="flex min-h-screen items-center justify-center p-4">
      <Card className="max-w-sm text-center">
        <h1 className="text-lg font-extrabold tracking-tight">Not authorized</h1>
        <p className="mt-2 text-sm font-medium text-ink/60">
          {user?.email} is not an admin. Ask an existing admin to add your UID to
          <code className="mx-1 rounded border border-ink/20 bg-ink/[0.04] px-1">
            ADMIN_UIDS
          </code>
          .
        </p>
        <Button variant="secondary" className="mt-4" onClick={logout}>
          Sign out
        </Button>
      </Card>
    </div>
  );
}

function Gate() {
  const { user, isAdmin, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner />
      </div>
    );
  }
  if (!user) return <LoginPage />;
  if (!isAdmin) return <NotAuthorized />;

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Navigate to="/admin/creators" replace />} />
        <Route path="creators" element={<CreatorQueuePage />} />
        <Route path="quests" element={<QuestManagerPage />} />
        <Route path="seeding" element={<EventSeedingPage />} />
        <Route path="density" element={<DensityViewPage />} />
        <Route path="users" element={<UserManagementPage />} />
        <Route path="notifications" element={<NotificationTemplatesPage />} />
        <Route path="*" element={<Navigate to="/admin/creators" replace />} />
      </Route>
    </Routes>
  );
}

export default function AdminApp() {
  return (
    <div className="admin-root">
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <Gate />
        </AuthProvider>
      </QueryClientProvider>
    </div>
  );
}
