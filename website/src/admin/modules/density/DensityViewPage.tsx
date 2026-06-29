import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@admin/lib/api";
import { track } from "@admin/lib/analytics";
import type { DensityResponse, ExpiringEvent, LaunchArea } from "@admin/lib/types";
import { PageHeader } from "@admin/components/Layout";
import { PlaceSearch } from "@admin/components/PlaceSearch";
import {
  Badge,
  Button,
  Card,
  EmptyState,
  ErrorState,
  Field,
  Input,
  Modal,
  Spinner,
  Table,
  Td,
  Th,
} from "@admin/components/ui";

import { formatDateTime as fmt } from "@admin/lib/format";

export function DensityViewPage() {
  const {
    data,
    isLoading,
    error,
    refetch,
    isFetching,
  } = useQuery({
    queryKey: ["density"],
    queryFn: () => api<DensityResponse>("/admin/density"),
  });

  return (
    <>
      <PageHeader
        title="Density View"
        subtitle="Monitor active events per launch area and intervene before the map goes empty."
        action={
          <Button
            variant="secondary"
            disabled={isFetching}
            onClick={() => refetch()}
          >
            Refresh
          </Button>
        }
      />

      {isLoading ? (
        <Card>
          <Spinner />
        </Card>
      ) : error ? (
        <Card>
          <ErrorState message={(error as Error).message} />
        </Card>
      ) : !data || data.areas.length === 0 ? (
        <Card>
          <EmptyState message="No launch areas configured yet." />
        </Card>
      ) : (
        <div className="grid grid-cols-1 gap-5 md:grid-cols-2">
          {data.areas.map((d) => (
            <Card key={d.area.id}>
              <div className="flex items-start justify-between">
                <div>
                  <div className="text-lg font-bold text-gray-900">
                    {d.area.name}
                  </div>
                  <div className="text-xs text-gray-400">
                    {d.area.radius_km} km radius
                  </div>
                </div>
                {d.below_threshold ? (
                  <Badge tone="red">
                    Below threshold (&lt;{data.threshold})
                  </Badge>
                ) : (
                  <Badge tone="green">Healthy</Badge>
                )}
              </div>

              <div className="mt-4 flex items-baseline gap-2">
                <span
                  className={
                    d.below_threshold
                      ? "text-4xl font-extrabold text-red-600"
                      : "text-4xl font-extrabold text-gray-900"
                  }
                >
                  {d.active_event_count}
                </span>
                <span className="text-sm text-gray-400">active events</span>
              </div>

              <div className="mt-4">
                <div className="mb-1 text-xs font-bold uppercase tracking-wide text-gray-400">
                  Expiring in 24h
                </div>
                {d.expiring_24h.length === 0 ? (
                  <div className="text-sm text-gray-400">
                    No events expiring in 24h
                  </div>
                ) : (
                  <ul className="space-y-2">
                    {d.expiring_24h.map((e: ExpiringEvent) => (
                      <li
                        key={e.id}
                        className="flex items-start justify-between gap-2"
                      >
                        <div>
                          <div className="text-sm font-semibold text-gray-800">
                            {e.title}
                          </div>
                          <div className="text-xs text-gray-400">
                            {e.location_name} · {fmt(e.date_time)}
                          </div>
                        </div>
                        {e.seeded && <Badge tone="blue">Seeded</Badge>}
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}

      <div className="mt-6">
        <LaunchAreasSection />
      </div>
    </>
  );
}

function LaunchAreasSection() {
  const qc = useQueryClient();
  const [editing, setEditing] = useState<LaunchArea | null>(null);
  const [creating, setCreating] = useState(false);

  const { data, isLoading, error } = useQuery({
    queryKey: ["launch-areas"],
    queryFn: () => api<LaunchArea[]>("/admin/launch-areas"),
  });

  const del = useMutation({
    mutationFn: (id: string) =>
      api(`/admin/launch-areas/${id}`, { method: "DELETE" }),
    onSuccess: (_d, id) => {
      track("admin_launch_area_deleted", { id });
      qc.invalidateQueries({ queryKey: ["launch-areas"] });
      qc.invalidateQueries({ queryKey: ["density"] });
    },
  });

  return (
    <Card>
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-bold text-gray-900">Launch areas</h2>
        <Button onClick={() => setCreating(true)}>Add launch area</Button>
      </div>

      {isLoading ? (
        <Spinner />
      ) : error ? (
        <ErrorState message={(error as Error).message} />
      ) : !data || data.length === 0 ? (
        <EmptyState message="No launch areas yet." />
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>Name</Th>
              <Th>Center</Th>
              <Th>Radius</Th>
              <Th>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {data.map((a) => (
              <tr key={a.id}>
                <Td>
                  <div className="font-semibold">{a.name}</div>
                </Td>
                <Td className="text-gray-500">
                  {a.center_lat.toFixed(4)}, {a.center_lng.toFixed(4)}
                </Td>
                <Td className="text-gray-500">{a.radius_km} km</Td>
                <Td>
                  <div className="flex gap-2">
                    <Button
                      variant="secondary"
                      onClick={() => setEditing(a)}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="danger"
                      disabled={del.isPending}
                      onClick={() => {
                        if (
                          window.confirm(
                            `Delete launch area "${a.name}"?`,
                          )
                        ) {
                          del.mutate(a.id);
                        }
                      }}
                    >
                      Delete
                    </Button>
                  </div>
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}

      {del.error && (
        <div className="mt-4">
          <ErrorState message={(del.error as Error).message} />
        </div>
      )}

      {creating && (
        <LaunchAreaModal onClose={() => setCreating(false)} />
      )}
      {editing && (
        <LaunchAreaModal area={editing} onClose={() => setEditing(null)} />
      )}
    </Card>
  );
}

interface LaunchAreaForm {
  name: string;
  center_lat: string;
  center_lng: string;
  radius_km: string;
}

function LaunchAreaModal({
  area,
  onClose,
}: {
  area?: LaunchArea;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const [form, setForm] = useState<LaunchAreaForm>({
    name: area?.name ?? "",
    center_lat: area ? String(area.center_lat) : "",
    center_lng: area ? String(area.center_lng) : "",
    radius_km: area ? String(area.radius_km) : "15",
  });

  const save = useMutation({
    mutationFn: () => {
      const body = {
        name: form.name.trim(),
        center_lat: Number(form.center_lat),
        center_lng: Number(form.center_lng),
        radius_km: Number(form.radius_km),
      };
      return area
        ? api<LaunchArea>(`/admin/launch-areas/${area.id}`, {
            method: "PUT",
            body,
          })
        : api<LaunchArea>("/admin/launch-areas", {
            method: "POST",
            body,
          });
    },
    onSuccess: () => {
      if (!area) track("admin_launch_area_created", { name: form.name.trim() });
      qc.invalidateQueries({ queryKey: ["launch-areas"] });
      qc.invalidateQueries({ queryKey: ["density"] });
      onClose();
    },
  });

  const valid =
    form.name.trim().length > 0 &&
    form.center_lat.trim() !== "" &&
    !Number.isNaN(Number(form.center_lat)) &&
    form.center_lng.trim() !== "" &&
    !Number.isNaN(Number(form.center_lng)) &&
    form.radius_km.trim() !== "" &&
    Number(form.radius_km) > 0;

  return (
    <Modal
      open
      onClose={onClose}
      title={area ? "Edit launch area" : "Add launch area"}
    >
      <div className="space-y-4">
        <Field label="Name">
          <Input
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            placeholder="e.g. Bandra"
          />
        </Field>
        <Field
          label="Find center"
          hint="Search a place to set the center; fine-tune below if needed."
        >
          <PlaceSearch
            placeholder="Search an area or landmark…"
            onSelect={(place) =>
              setForm((prev) => ({
                ...prev,
                center_lat: String(place.lat),
                center_lng: String(place.lng),
                name: prev.name.trim() === "" ? place.name : prev.name,
              }))
            }
          />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Center latitude">
            <Input
              type="number"
              value={form.center_lat}
              onChange={(e) =>
                setForm({ ...form, center_lat: e.target.value })
              }
              placeholder="19.0596"
            />
          </Field>
          <Field label="Center longitude">
            <Input
              type="number"
              value={form.center_lng}
              onChange={(e) =>
                setForm({ ...form, center_lng: e.target.value })
              }
              placeholder="72.8295"
            />
          </Field>
        </div>
        <Field label="Radius (km)">
          <Input
            type="number"
            value={form.radius_km}
            onChange={(e) => setForm({ ...form, radius_km: e.target.value })}
          />
        </Field>

        {save.error && <ErrorState message={(save.error as Error).message} />}

        <div className="flex justify-end gap-2 pt-2">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={!valid || save.isPending}
            onClick={() => save.mutate()}
          >
            {area ? "Save changes" : "Create"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
