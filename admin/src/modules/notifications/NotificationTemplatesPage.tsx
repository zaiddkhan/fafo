import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { track } from "@/lib/analytics";
import type {
  NotificationTemplate,
  NotificationTemplateVersion,
} from "@/lib/types";
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
  Spinner,
  Textarea,
} from "@/components/ui";

function fmt(ts?: string | null): string {
  if (!ts) return "—";
  return new Date(ts).toLocaleString();
}

function humanize(s: string): string {
  return s
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function truncate(s: string, n = 90): string {
  return s.length > n ? `${s.slice(0, n)}…` : s;
}

// Sample values used to render the live lock-screen preview.
function sampleFor(variable: string): string {
  const v = variable.toLowerCase();
  if (v.endsWith("_name") || v === "name") return "Alex";
  if (v === "event_title" || v === "quest_title") return "Downtown Run";
  if (v === "group_name") return "Weekend Crew";
  if (v.includes("minute")) return "10";
  return variable.toUpperCase();
}

function interpolate(body: string): string {
  return body.replace(/\{(\w+)\}/g, (_m, name: string) => sampleFor(name));
}

function groupByType(
  templates: NotificationTemplate[],
): Array<[string, NotificationTemplate[]]> {
  const map = new Map<string, NotificationTemplate[]>();
  for (const t of templates) {
    const arr = map.get(t.type);
    if (arr) arr.push(t);
    else map.set(t.type, [t]);
  }
  return Array.from(map.entries());
}

export function NotificationTemplatesPage() {
  const [selected, setSelected] = useState<NotificationTemplate | null>(null);
  const { data, isLoading, error } = useQuery({
    queryKey: ["notif-templates"],
    queryFn: () => api<NotificationTemplate[]>("/admin/notification-templates"),
  });

  const groups = useMemo(() => (data ? groupByType(data) : []), [data]);

  return (
    <>
      <PageHeader
        title="Notification Templates"
        subtitle="Edit copy, sound, and params per notification type. Send timing is controlled by the backend engine."
      />
      {isLoading ? (
        <Card>
          <Spinner />
        </Card>
      ) : error ? (
        <Card>
          <ErrorState message={(error as Error).message} />
        </Card>
      ) : !data || data.length === 0 ? (
        <Card>
          <EmptyState message="No notification templates configured." />
        </Card>
      ) : (
        <div className="space-y-6">
          {groups.map(([type, templates]) => (
            <div key={type}>
              <h2 className="mb-2 text-sm font-bold uppercase tracking-wide text-gray-500">
                {humanize(type)}
              </h2>
              <Card className="space-y-2">
                {templates.map((t) => (
                  <div
                    key={t.id}
                    className="flex items-center justify-between gap-4 rounded-xl border border-gray-100 px-3 py-2.5"
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold">
                          {humanize(t.subtype)}
                        </span>
                        <Badge tone={t.enabled ? "green" : "gray"}>
                          {t.enabled ? "On" : "Off"}
                        </Badge>
                        <span className="text-xs text-gray-400">
                          v{t.version}
                        </span>
                      </div>
                      <div className="mt-0.5 truncate text-sm text-gray-500">
                        {truncate(t.body)}
                      </div>
                    </div>
                    <Button variant="secondary" onClick={() => setSelected(t)}>
                      Edit
                    </Button>
                  </div>
                ))}
              </Card>
            </div>
          ))}
        </div>
      )}
      {selected && (
        <EditTemplateModal
          template={selected}
          onClose={() => setSelected(null)}
        />
      )}
    </>
  );
}

function EditTemplateModal({
  template,
  onClose,
}: {
  template: NotificationTemplate;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const [body, setBody] = useState(template.body);
  const [sound, setSound] = useState(template.sound ?? "");
  const [enabled, setEnabled] = useState(template.enabled);
  const [paramsText, setParamsText] = useState(
    JSON.stringify(template.params, null, 2),
  );
  const [paramsError, setParamsError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  const versions = useQuery({
    queryKey: ["notif-versions", template.id],
    queryFn: () =>
      api<NotificationTemplateVersion[]>(
        `/admin/notification-templates/${template.id}/versions`,
      ),
  });

  const save = useMutation({
    mutationFn: (payload: {
      body: string;
      sound: string | null;
      enabled: boolean;
      params: Record<string, unknown>;
    }) =>
      api(`/admin/notification-templates/${template.id}`, {
        method: "PUT",
        body: payload,
      }),
    onSuccess: () => {
      track("admin_notif_template_updated", { id: template.id });
      qc.invalidateQueries({ queryKey: ["notif-templates"] });
      qc.invalidateQueries({ queryKey: ["notif-versions", template.id] });
      setSaved(true);
    },
  });

  const rollback = useMutation({
    mutationFn: (version: number) =>
      api(
        `/admin/notification-templates/${template.id}/rollback/${version}`,
        { method: "POST" },
      ),
    onSuccess: (_d, version) => {
      track("admin_notif_template_rollback", { id: template.id, version });
      qc.invalidateQueries({ queryKey: ["notif-templates"] });
      qc.invalidateQueries({ queryKey: ["notif-versions", template.id] });
    },
  });

  useEffect(() => {
    if (saved) setSaved(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [body, sound, enabled, paramsText]);

  function handleSave() {
    let params: Record<string, unknown>;
    try {
      const parsed: unknown = JSON.parse(paramsText);
      if (
        typeof parsed !== "object" ||
        parsed === null ||
        Array.isArray(parsed)
      ) {
        setParamsError("Params must be a JSON object.");
        return;
      }
      params = parsed as Record<string, unknown>;
    } catch (e) {
      setParamsError(`Invalid JSON: ${(e as Error).message}`);
      return;
    }
    setParamsError(null);
    save.mutate({
      body,
      sound: sound.trim() === "" ? null : sound,
      enabled,
      params,
    });
  }

  return (
    <Modal open onClose={onClose} title={humanize(template.subtype)}>
      <div className="space-y-4">
        <div className="text-xs text-gray-400">
          {humanize(template.type)} · v{template.version}
        </div>

        {template.variables.length > 0 && (
          <div>
            <div className="mb-1.5 text-xs font-bold text-gray-700">
              Available variables
            </div>
            <div className="flex flex-wrap gap-1.5">
              {template.variables.map((v) => (
                <Badge key={v} tone="blue">{`{${v}}`}</Badge>
              ))}
            </div>
          </div>
        )}

        <Field label="Body">
          <Textarea
            rows={3}
            value={body}
            onChange={(e) => setBody(e.target.value)}
          />
        </Field>

        {/* Lock-screen preview */}
        <div>
          <div className="mb-1.5 text-xs font-bold text-gray-700">
            Lock-screen preview
          </div>
          <div className="rounded-2xl bg-gradient-to-b from-gray-800 to-gray-900 p-4">
            <div className="rounded-xl bg-white/10 px-3.5 py-3 backdrop-blur">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="flex h-5 w-5 items-center justify-center rounded-md bg-brand-500 text-[10px] font-extrabold text-white">
                    W
                  </div>
                  <span className="text-xs font-semibold uppercase tracking-wide text-white/70">
                    Fafo
                  </span>
                </div>
                <span className="text-xs text-white/50">now</span>
              </div>
              <div className="mt-1.5 text-sm leading-snug text-white">
                {interpolate(body) || (
                  <span className="text-white/40">Empty message</span>
                )}
              </div>
            </div>
          </div>
        </div>

        <Field label="Sound" hint="Distinct sound key for this notification.">
          <Input
            value={sound}
            onChange={(e) => setSound(e.target.value)}
            placeholder="default"
          />
        </Field>

        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={enabled}
            onChange={(e) => setEnabled(e.target.checked)}
            className="h-4 w-4 rounded border-gray-300 text-brand-500 focus:ring-brand-100"
          />
          <span className="text-sm font-semibold text-gray-700">Enabled</span>
        </label>

        <Field label="Params (JSON)">
          <Textarea
            rows={4}
            value={paramsText}
            onChange={(e) => setParamsText(e.target.value)}
            className="font-mono text-xs"
          />
        </Field>
        {paramsError && <ErrorState message={paramsError} />}

        {save.error && <ErrorState message={(save.error as Error).message} />}
        {saved && !save.isPending && (
          <div className="rounded-lg bg-green-50 px-4 py-3 text-sm text-green-700">
            Template saved. New version created.
          </div>
        )}

        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            Close
          </Button>
          <Button
            variant="primary"
            disabled={save.isPending}
            onClick={handleSave}
          >
            Save changes
          </Button>
        </div>

        {/* Version history */}
        <div className="border-t border-gray-200 pt-4">
          <div className="mb-2 text-xs font-bold uppercase tracking-wide text-gray-400">
            Version history
          </div>
          {versions.isLoading ? (
            <Spinner />
          ) : versions.error ? (
            <ErrorState message={(versions.error as Error).message} />
          ) : !versions.data || versions.data.length === 0 ? (
            <EmptyState message="No prior versions." />
          ) : (
            <div className="space-y-2">
              {rollback.error && (
                <ErrorState message={(rollback.error as Error).message} />
              )}
              {versions.data.map((v) => (
                <div
                  key={v.version}
                  className="flex items-start justify-between gap-3 rounded-xl border border-gray-100 px-3 py-2.5"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <Badge tone="gray">v{v.version}</Badge>
                      <span className="text-xs text-gray-400">
                        {fmt(v.updated_at)}
                      </span>
                    </div>
                    <div className="mt-0.5 truncate text-sm text-gray-500">
                      {truncate(v.body)}
                    </div>
                  </div>
                  <Button
                    variant="secondary"
                    disabled={rollback.isPending}
                    onClick={() => rollback.mutate(v.version)}
                  >
                    Roll back
                  </Button>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </Modal>
  );
}
