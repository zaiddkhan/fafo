import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { track } from "@/lib/analytics";
import type { AdminEventListItem, Category } from "@/lib/types";
import { PageHeader } from "@/components/Layout";
import {
  Badge,
  Button,
  Card,
  EmptyState,
  ErrorState,
  Field,
  Input,
  Modal,
  Select,
  Spinner,
  Table,
  Td,
  Textarea,
  Th,
} from "@/components/ui";

type SeededFilter = "all" | "seeded" | "organic";
type EventType = "normal" | "volunteering";

interface EventCreateRequest {
  title: string;
  description?: string;
  category_id: string;
  event_type: EventType;
  custom_emoji?: string;
  lat: number;
  lng: number;
  location_name: string;
  date_time: string;
  capacity?: number;
  organizer_name?: string;
  organizer_contact?: string;
  organizer_instagram?: string;
}

function fmt(ts?: string | null): string {
  if (!ts) return "—";
  return new Date(ts).toLocaleString();
}

function filterParam(filter: SeededFilter): boolean | undefined {
  if (filter === "seeded") return true;
  if (filter === "organic") return false;
  return undefined;
}

export function EventSeedingPage() {
  const [seededFilter, setSeededFilter] = useState<SeededFilter>("all");
  const [creating, setCreating] = useState(false);

  const { data, isLoading, error } = useQuery({
    queryKey: ["admin-events", seededFilter],
    queryFn: () =>
      api<AdminEventListItem[]>("/admin/events", {
        query: { upcoming_only: true, seeded: filterParam(seededFilter) },
      }),
  });

  return (
    <>
      <PageHeader
        title="Event Seeding"
        subtitle="Team-created events used to populate launch areas before public release."
        action={<Button onClick={() => setCreating(true)}>Seed event</Button>}
      />
      <Card>
        <div className="mb-4 flex items-center gap-2">
          <span className="text-xs font-bold uppercase tracking-wide text-gray-500">
            Filter
          </span>
          <div className="w-48">
            <Select
              value={seededFilter}
              onChange={(e) => setSeededFilter(e.target.value as SeededFilter)}
            >
              <option value="all">All</option>
              <option value="seeded">Seeded only</option>
              <option value="organic">Organic only</option>
            </Select>
          </div>
        </div>
        {isLoading ? (
          <Spinner />
        ) : error ? (
          <ErrorState message={(error as Error).message} />
        ) : !data || data.length === 0 ? (
          <EmptyState message="No upcoming events." />
        ) : (
          <Table>
            <thead>
              <tr>
                <Th>Title</Th>
                <Th>Location</Th>
                <Th>Date</Th>
                <Th>Joinees</Th>
                <Th>Source</Th>
              </tr>
            </thead>
            <tbody>
              {data.map((ev) => (
                <tr key={ev.id}>
                  <Td>
                    <div className="font-semibold">{ev.title}</div>
                  </Td>
                  <Td className="text-gray-500">{ev.location_name}</Td>
                  <Td className="text-gray-500">{fmt(ev.date_time)}</Td>
                  <Td>{ev.joinee_count}</Td>
                  <Td>
                    <Badge tone={ev.seeded ? "blue" : "gray"}>
                      {ev.seeded ? "Seeded" : "Organic"}
                    </Badge>
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        )}
      </Card>
      {creating && <SeedEventModal onClose={() => setCreating(false)} />}
    </>
  );
}

function SeedEventModal({ onClose }: { onClose: () => void }) {
  const qc = useQueryClient();

  const { data: categories, isLoading: categoriesLoading } = useQuery({
    queryKey: ["categories"],
    queryFn: () => api<Category[]>("/categories"),
  });

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [eventType, setEventType] = useState<EventType>("normal");
  const [customEmoji, setCustomEmoji] = useState("");
  const [lat, setLat] = useState("");
  const [lng, setLng] = useState("");
  const [locationName, setLocationName] = useState("");
  const [dateTime, setDateTime] = useState("");
  const [capacity, setCapacity] = useState("");
  const [organizerName, setOrganizerName] = useState("");
  const [organizerContact, setOrganizerContact] = useState("");
  const [organizerInstagram, setOrganizerInstagram] = useState("");
  const [validationError, setValidationError] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: (body: EventCreateRequest) =>
      api<AdminEventListItem>("/admin/events", { method: "POST", body }),
    onSuccess: (created) => {
      track("admin_event_seeded", {
        event_id: created.id,
        category_id: created.category_id,
        event_type: eventType,
      });
      qc.invalidateQueries({ queryKey: ["admin-events"] });
      onClose();
    },
  });

  function submit() {
    setValidationError(null);

    if (!title.trim()) {
      setValidationError("Title is required.");
      return;
    }
    if (!categoryId) {
      setValidationError("Category is required.");
      return;
    }
    if (!locationName.trim()) {
      setValidationError("Location name is required.");
      return;
    }

    const latNum = Number(lat);
    const lngNum = Number(lng);
    if (lat.trim() === "" || Number.isNaN(latNum)) {
      setValidationError("A valid latitude is required.");
      return;
    }
    if (lng.trim() === "" || Number.isNaN(lngNum)) {
      setValidationError("A valid longitude is required.");
      return;
    }

    if (!dateTime) {
      setValidationError("Date & time is required.");
      return;
    }
    const when = new Date(dateTime);
    if (Number.isNaN(when.getTime())) {
      setValidationError("Date & time is invalid.");
      return;
    }
    if (when.getTime() <= Date.now()) {
      setValidationError("Date & time must be in the future.");
      return;
    }

    let capacityNum: number | undefined;
    if (capacity.trim() !== "") {
      capacityNum = Number(capacity);
      if (Number.isNaN(capacityNum)) {
        setValidationError("Capacity must be a number.");
        return;
      }
    }

    const body: EventCreateRequest = {
      title: title.trim(),
      category_id: categoryId,
      event_type: eventType,
      lat: latNum,
      lng: lngNum,
      location_name: locationName.trim(),
      date_time: when.toISOString(),
    };
    if (description.trim()) body.description = description.trim();
    if (customEmoji.trim()) body.custom_emoji = customEmoji.trim();
    if (capacityNum !== undefined) body.capacity = capacityNum;
    if (organizerName.trim()) body.organizer_name = organizerName.trim();
    if (organizerContact.trim()) body.organizer_contact = organizerContact.trim();
    if (organizerInstagram.trim())
      body.organizer_instagram = organizerInstagram.trim();

    create.mutate(body);
  }

  return (
    <Modal open onClose={onClose} title="Seed event">
      <div className="max-h-[70vh] space-y-4 overflow-y-auto pr-1">
        <Field label="Title">
          <Input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Event title"
          />
        </Field>

        <Field label="Description" hint="Optional">
          <Textarea
            rows={3}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
        </Field>

        <Field label="Category">
          <Select
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            disabled={categoriesLoading}
          >
            <option value="">Select a category</option>
            {categories?.map((c) => (
              <option key={c.id} value={c.id}>
                {c.emoji} {c.name}
              </option>
            ))}
          </Select>
        </Field>

        <Field label="Event type">
          <Select
            value={eventType}
            onChange={(e) => setEventType(e.target.value as EventType)}
          >
            <option value="normal">Normal</option>
            <option value="volunteering">Volunteering</option>
          </Select>
        </Field>

        <Field label="Custom emoji" hint="Optional">
          <Input
            value={customEmoji}
            onChange={(e) => setCustomEmoji(e.target.value)}
            placeholder="🎉"
          />
        </Field>

        <div className="grid grid-cols-2 gap-3">
          <Field label="Latitude">
            <Input
              type="number"
              value={lat}
              onChange={(e) => setLat(e.target.value)}
              placeholder="0.0"
            />
          </Field>
          <Field label="Longitude">
            <Input
              type="number"
              value={lng}
              onChange={(e) => setLng(e.target.value)}
              placeholder="0.0"
            />
          </Field>
        </div>

        <Field label="Location name">
          <Input
            value={locationName}
            onChange={(e) => setLocationName(e.target.value)}
            placeholder="Venue or address"
          />
        </Field>

        <Field label="Date & time" hint="Must be in the future">
          <Input
            type="datetime-local"
            value={dateTime}
            onChange={(e) => setDateTime(e.target.value)}
          />
        </Field>

        <Field label="Capacity" hint="Optional">
          <Input
            type="number"
            value={capacity}
            onChange={(e) => setCapacity(e.target.value)}
            placeholder="Unlimited"
          />
        </Field>

        <Field label="Organizer name" hint="Optional">
          <Input
            value={organizerName}
            onChange={(e) => setOrganizerName(e.target.value)}
          />
        </Field>

        <Field label="Organizer contact" hint="Optional">
          <Input
            value={organizerContact}
            onChange={(e) => setOrganizerContact(e.target.value)}
          />
        </Field>

        <Field label="Organizer Instagram" hint="Optional">
          <Input
            value={organizerInstagram}
            onChange={(e) => setOrganizerInstagram(e.target.value)}
            placeholder="@handle"
          />
        </Field>

        {validationError && <ErrorState message={validationError} />}
        {create.error && <ErrorState message={(create.error as Error).message} />}

        <div className="flex justify-end gap-2 pt-2">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button disabled={create.isPending} onClick={submit}>
            Seed event
          </Button>
        </div>
      </div>
    </Modal>
  );
}
