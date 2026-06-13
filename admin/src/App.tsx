import { Navigate, Route, Routes } from "react-router-dom";
import { useAuth } from "./auth/AuthProvider";
import { LoginPage } from "./auth/LoginPage";
import { Layout } from "./components/Layout";
import { Button, Card, Spinner } from "./components/ui";
import { CreatorQueuePage } from "./modules/creators/CreatorQueuePage";
import { QuestManagerPage } from "./modules/quests/QuestManagerPage";
import { EventSeedingPage } from "./modules/seeding/EventSeedingPage";
import { DensityViewPage } from "./modules/density/DensityViewPage";
import { UserManagementPage } from "./modules/users/UserManagementPage";
import { NotificationTemplatesPage } from "./modules/notifications/NotificationTemplatesPage";
import { AnalyticsPage } from "./modules/analytics/AnalyticsPage";

function NotAuthorized() {
  const { user, logout } = useAuth();
  return (
    <div className="flex min-h-full items-center justify-center p-4">
      <Card className="max-w-sm text-center">
        <h1 className="text-lg font-bold">Not authorized</h1>
        <p className="mt-2 text-sm text-gray-500">
          {user?.email} is not an admin. Ask an existing admin to add your UID to
          <code className="mx-1 rounded bg-gray-100 px-1">ADMIN_UIDS</code>.
        </p>
        <Button variant="secondary" className="mt-4" onClick={logout}>
          Sign out
        </Button>
      </Card>
    </div>
  );
}

export default function App() {
  const { user, isAdmin, loading } = useAuth();

  if (loading) return <Spinner />;
  if (!user) return <LoginPage />;
  if (!isAdmin) return <NotAuthorized />;

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Navigate to="/creators" replace />} />
        <Route path="/creators" element={<CreatorQueuePage />} />
        <Route path="/quests" element={<QuestManagerPage />} />
        <Route path="/seeding" element={<EventSeedingPage />} />
        <Route path="/density" element={<DensityViewPage />} />
        <Route path="/users" element={<UserManagementPage />} />
        <Route path="/notifications" element={<NotificationTemplatesPage />} />
        <Route path="/analytics" element={<AnalyticsPage />} />
        <Route path="*" element={<Navigate to="/creators" replace />} />
      </Route>
    </Routes>
  );
}
