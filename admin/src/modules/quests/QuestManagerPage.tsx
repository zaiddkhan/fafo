import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { track } from "@/lib/analytics";
import type { AdminQuest, Area, QuestDifficulty } from "@/lib/types";
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

const difficultyTone: Record<QuestDifficulty, "green" | "amber" | "red"> = {
  easy: "green",
  medium: "amber",
  hard: "red",
};

interface QuestCreateRequest {
  title: string;
  description?: string;
  difficulty: QuestDifficulty;
  city?: string;
  area?: Area;
  published: boolean;
}

function scopeLabel(quest: AdminQuest): string {
  if (quest.city) return `Citywide: ${quest.city}`;
  if (quest.area) return "Area-specific";
  return "—";
}

export function QuestManagerPage() {
  const qc = useQueryClient();
  const [creating, setCreating] = useState(false);
  const { data, isLoading, error } = useQuery({
    queryKey: ["quests"],
    queryFn: () => api<AdminQuest[]>("/admin/quests"),
  });

  const toggle = useMutation({
    mutationFn: (vars: { id: string; published: boolean }) =>
      api(`/quests/${vars.id}`, {
        method: "PUT",
        body: { published: vars.published },
      }),
    onSuccess: (_d, vars) => {
      track("admin_quest_publish_toggle", { published: vars.published });
      qc.invalidateQueries({ queryKey: ["quests"] });
    },
  });

  return (
    <>
      <PageHeader
        title="Quest Manager"
        subtitle="FuFa-team-only Side Quests. Publishing pushes a quest live in real time."
        action={
          <Button onClick={() => setCreating(true)}>New quest</Button>
        }
      />
      <Card>
        {isLoading ? (
          <Spinner />
        ) : error ? (
          <ErrorState message={(error as Error).message} />
        ) : !data || data.length === 0 ? (
          <EmptyState message="No quests yet. Create your first Side Quest." />
        ) : (
          <Table>
            <thead>
              <tr>
                <Th>Title</Th>
                <Th>Difficulty</Th>
                <Th>Targeting</Th>
                <Th>State</Th>
                <Th>Activations</Th>
                <Th>Action</Th>
              </tr>
            </thead>
            <tbody>
              {data.map((q) => (
                <tr key={q.id}>
                  <Td>
                    <div className="font-semibold">{q.title}</div>
                  </Td>
                  <Td>
                    <Badge tone={difficultyTone[q.difficulty]}>
                      {q.difficulty}
                    </Badge>
                  </Td>
                  <Td className="text-gray-500">{scopeLabel(q)}</Td>
                  <Td>
                    <Badge tone={q.published ? "green" : "gray"}>
                      {q.published ? "Live" : "Draft"}
                    </Badge>
                  </Td>
                  <Td className="text-gray-500">
                    {q.activation_count} activations
                  </Td>
                  <Td>
                    <Button
                      variant="secondary"
                      disabled={toggle.isPending}
                      onClick={() =>
                        toggle.mutate({ id: q.id, published: !q.published })
                      }
                    >
                      {q.published ? "Unpublish" : "Publish"}
                    </Button>
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        )}
        {toggle.error && (
          <div className="mt-4">
            <ErrorState message={(toggle.error as Error).message} />
          </div>
        )}
      </Card>
      {creating && <CreateQuestModal onClose={() => setCreating(false)} />}
    </>
  );
}

function CreateQuestModal({ onClose }: { onClose: () => void }) {
  const qc = useQueryClient();
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [difficulty, setDifficulty] = useState<QuestDifficulty>("easy");
  const [scope, setScope] = useState<"citywide" | "area">("citywide");
  const [city, setCity] = useState("");
  const [lat, setLat] = useState("");
  const [lng, setLng] = useState("");
  const [radiusKm, setRadiusKm] = useState("15");
  const [published, setPublished] = useState(true);

  const create = useMutation({
    mutationFn: (body: QuestCreateRequest) =>
      api<AdminQuest>("/quests", { method: "POST", body }),
    onSuccess: (_d, body) => {
      track("admin_quest_created", {
        difficulty: body.difficulty,
        published: body.published,
        scope: body.area ? "area" : "citywide",
      });
      qc.invalidateQueries({ queryKey: ["quests"] });
      onClose();
    },
  });

  const trimmedTitle = title.trim();
  const isAreaValid =
    scope === "area" && lat.trim() !== "" && lng.trim() !== "" && radiusKm.trim() !== "";
  const canSubmit =
    trimmedTitle !== "" && (scope === "citywide" ? city.trim() !== "" : isAreaValid);

  function handleSubmit() {
    if (!canSubmit) return;
    const description_ = description.trim();
    const body: QuestCreateRequest = {
      title: trimmedTitle,
      difficulty,
      published,
    };
    if (description_) body.description = description_;
    if (scope === "area") {
      body.area = {
        lat: Number(lat),
        lng: Number(lng),
        radius_km: Number(radiusKm),
      };
    } else {
      body.city = city.trim();
    }
    create.mutate(body);
  }

  return (
    <Modal open onClose={onClose} title="New Side Quest">
      <div className="space-y-4">
        <Field label="Title">
          <Input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Find the hidden mural"
          />
        </Field>

        <Field label="Description" hint="Optional">
          <Textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={3}
          />
        </Field>

        <Field label="Difficulty">
          <Select
            value={difficulty}
            onChange={(e) => setDifficulty(e.target.value as QuestDifficulty)}
          >
            <option value="easy">Easy</option>
            <option value="medium">Medium</option>
            <option value="hard">Hard</option>
          </Select>
        </Field>

        <Field label="Targeting scope">
          <Select
            value={scope}
            onChange={(e) => setScope(e.target.value as "citywide" | "area")}
          >
            <option value="citywide">Citywide</option>
            <option value="area">Area-specific</option>
          </Select>
        </Field>

        {scope === "citywide" ? (
          <Field label="City">
            <Input
              value={city}
              onChange={(e) => setCity(e.target.value)}
              placeholder="Bengaluru"
            />
          </Field>
        ) : (
          <div className="grid grid-cols-3 gap-3">
            <Field label="Lat">
              <Input
                type="number"
                value={lat}
                onChange={(e) => setLat(e.target.value)}
              />
            </Field>
            <Field label="Lng">
              <Input
                type="number"
                value={lng}
                onChange={(e) => setLng(e.target.value)}
              />
            </Field>
            <Field label="Radius (km)">
              <Input
                type="number"
                value={radiusKm}
                onChange={(e) => setRadiusKm(e.target.value)}
              />
            </Field>
          </div>
        )}

        <label className="flex items-center gap-2 text-sm font-semibold text-gray-700">
          <input
            type="checkbox"
            checked={published}
            onChange={(e) => setPublished(e.target.checked)}
            className="h-4 w-4 rounded border-gray-300 text-brand-500 focus:ring-brand-100"
          />
          Publish immediately (live in real time)
        </label>

        {create.error && <ErrorState message={(create.error as Error).message} />}

        <div className="flex justify-end gap-2 pt-2">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={!canSubmit || create.isPending}
            onClick={handleSubmit}
          >
            Create quest
          </Button>
        </div>
      </div>
    </Modal>
  );
}
