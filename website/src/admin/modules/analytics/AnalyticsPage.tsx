import { Card, Table, Td, Th } from "@admin/components/ui";
import { PageHeader } from "@admin/components/Layout";

type EventRow = { name: string; description: string };

const PRODUCT_EVENTS: EventRow[] = [
  { name: "app_open", description: "App launched / brought to foreground." },
  { name: "event_created", description: "A user created a new event." },
  {
    name: "event_seeded",
    description:
      "An event was seeded into a launch area. Carries a `seeded` property to separate team-seeded vs organic activity.",
  },
  { name: "event_joined", description: "A user joined / RSVP'd to an event." },
  { name: "quest_activated", description: "A user activated a quest." },
  { name: "nudge_sent", description: "A nudge was delivered to a user." },
  { name: "creator_applied", description: "A user applied to become a creator." },
  { name: "creator_approved", description: "A creator application was approved." },
];

const ADMIN_EVENTS: EventRow[] = [
  {
    name: "admin_creator_action",
    description: "Admin approved, rejected, or otherwise actioned a creator.",
  },
  {
    name: "admin_quest_created",
    description: "Admin created a quest in the Quest Manager.",
  },
  {
    name: "admin_event_seeded",
    description: "Admin seeded an event from the Event Seeding module.",
  },
  {
    name: "admin_launch_area_created",
    description: "Admin defined a new launch area in the Density View.",
  },
  {
    name: "admin_user_action",
    description: "Admin actioned a user from User Management.",
  },
  {
    name: "admin_notif_template_updated",
    description: "Admin updated a notification template.",
  },
];

function EventTable({ rows }: { rows: EventRow[] }) {
  return (
    <Table>
      <thead>
        <tr>
          <Th>Event</Th>
          <Th>Description</Th>
        </tr>
      </thead>
      <tbody>
        {rows.map((row) => (
          <tr key={row.name}>
            <Td className="whitespace-nowrap font-mono text-xs font-semibold text-brand-700">
              {row.name}
            </Td>
            <Td className="text-gray-600">{row.description}</Td>
          </tr>
        ))}
      </tbody>
    </Table>
  );
}

export function AnalyticsPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Analytics"
        subtitle="A light reference of the events the product and this panel emit."
      />

      <Card>
        <h2 className="text-base font-bold text-gray-900">
          Product event taxonomy
        </h2>
        <p className="mt-1 mb-4 text-sm text-gray-500">
          Core events emitted by the Flutter app.
        </p>
        <EventTable rows={PRODUCT_EVENTS} />
      </Card>

      <Card>
        <h2 className="text-base font-bold text-gray-900">Admin panel events</h2>
        <p className="mt-1 mb-4 text-sm text-gray-500">
          Usage events emitted by this admin panel.
        </p>
        <EventTable rows={ADMIN_EVENTS} />
      </Card>

      <Card>
        <h2 className="text-base font-bold text-gray-900">
          In-panel visualization
        </h2>
        <p className="mt-2 text-sm leading-relaxed text-gray-600">
          The only data visualization built into this panel is the{" "}
          <span className="font-semibold text-gray-800">Density View</span>.
          It lives here because the launch-area radius logic is proprietary and
          cannot be replicated in third-party analytics tools.
        </p>
      </Card>
    </div>
  );
}
