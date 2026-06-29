import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@admin/lib/api";
import { track } from "@admin/lib/analytics";
import type { CreatorDetail, CreatorListItem, CreatorStatus } from "@admin/lib/types";
import { PageHeader } from "@admin/components/Layout";
import {
  Badge,
  Button,
  Card,
  EmptyState,
  ErrorState,
  Modal,
  Spinner,
  Table,
  Td,
  Th,
} from "@admin/components/ui";

const statusTone: Record<CreatorStatus, "amber" | "green" | "gray" | "red" | "blue"> = {
  pending: "amber",
  reapplied: "blue",
  approved: "green",
  revoked: "gray",
  rejected: "red",
};

import { formatDateTime as fmt } from "@admin/lib/format";

export function CreatorQueuePage() {
  const [selected, setSelected] = useState<string | null>(null);
  const { data, isLoading, error } = useQuery({
    queryKey: ["creators"],
    queryFn: () => api<CreatorListItem[]>("/admin/creators"),
  });

  return (
    <>
      <PageHeader
        title="Creator Queue"
        subtitle="Manual vetting of creator applications. No bulk actions."
      />
      <Card>
        {isLoading ? (
          <Spinner />
        ) : error ? (
          <ErrorState message={(error as Error).message} />
        ) : !data || data.length === 0 ? (
          <EmptyState message="No creator applications yet." />
        ) : (
          <Table>
            <thead>
              <tr>
                <Th>Applicant</Th>
                <Th>Submitted</Th>
                <Th>Status</Th>
                <Th>Action</Th>
              </tr>
            </thead>
            <tbody>
              {data.map((c) => (
                <tr key={c.uid}>
                  <Td>
                    <div className="font-semibold">{c.display_name}</div>
                    <div className="text-xs text-gray-400">
                      {c.username ? `@${c.username}` : c.uid}
                    </div>
                  </Td>
                  <Td className="text-gray-500">{fmt(c.submitted_at)}</Td>
                  <Td>
                    <div className="flex items-center gap-2">
                      <Badge tone={statusTone[c.status]}>{c.status}</Badge>
                      {c.reapplied && <Badge tone="blue">reapplied</Badge>}
                    </div>
                  </Td>
                  <Td>
                    <Button variant="secondary" onClick={() => setSelected(c.uid)}>
                      Review
                    </Button>
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        )}
      </Card>
      {selected && (
        <CreatorDetailModal uid={selected} onClose={() => setSelected(null)} />
      )}
    </>
  );
}

function CreatorDetailModal({
  uid,
  onClose,
}: {
  uid: string;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ["creator", uid],
    queryFn: () => api<CreatorDetail>(`/admin/creators/${uid}`),
  });

  const act = useMutation({
    mutationFn: (action: "approve" | "revoke") =>
      api(`/admin/creators/${uid}/${action}`, { method: "POST" }),
    onSuccess: (_d, action) => {
      track("admin_creator_action", { action, uid });
      qc.invalidateQueries({ queryKey: ["creators"] });
      qc.invalidateQueries({ queryKey: ["creator", uid] });
      onClose();
    },
  });

  return (
    <Modal open onClose={onClose} title="Creator application">
      {isLoading || !data ? (
        <Spinner />
      ) : (
        <div className="space-y-4">
          <div>
            <div className="text-lg font-bold">{data.display_name}</div>
            <div className="text-sm text-gray-400">
              {data.username ? `@${data.username}` : data.uid} · {data.phone}
            </div>
            <div className="mt-2 flex gap-2">
              <Badge tone={statusTone[data.status]}>{data.status}</Badge>
              {data.reapplied && <Badge tone="blue">reapplied</Badge>}
            </div>
          </div>

          <Section label="Purpose">
            <p className="text-sm text-gray-700">{data.purpose || "—"}</p>
          </Section>

          <Section label="Social links">
            <LinkList links={data.social_links} />
          </Section>
          <Section label="Supporting links">
            <LinkList links={data.relevant_links} />
          </Section>

          {data.history.length > 0 && (
            <Section label="Prior history">
              <ul className="space-y-1 text-sm text-gray-600">
                {data.history.map((h, i) => (
                  <li key={i}>
                    <Badge tone="gray">{h.status}</Badge>{" "}
                    <span className="text-gray-400">{fmt(h.at)}</span>
                  </li>
                ))}
              </ul>
            </Section>
          )}

          {act.error && <ErrorState message={(act.error as Error).message} />}

          <div className="flex justify-end gap-2 pt-2">
            <Button variant="ghost" onClick={onClose}>
              Close
            </Button>
            {data.is_creator && (
              <Button
                variant="danger"
                disabled={act.isPending}
                onClick={() => act.mutate("revoke")}
              >
                Revoke
              </Button>
            )}
            {data.status !== "approved" && (
              <Button
                variant="success"
                disabled={act.isPending}
                onClick={() => act.mutate("approve")}
              >
                Approve
              </Button>
            )}
          </div>
        </div>
      )}
    </Modal>
  );
}

function Section({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="mb-1 text-xs font-bold uppercase tracking-wide text-gray-400">
        {label}
      </div>
      {children}
    </div>
  );
}

function LinkList({ links }: { links: string[] }) {
  if (!links.length) return <span className="text-sm text-gray-400">—</span>;
  return (
    <div className="flex flex-col gap-0.5">
      {links.map((l) => (
        <a
          key={l}
          href={l}
          target="_blank"
          rel="noreferrer"
          className="text-sm text-brand-600 hover:underline"
        >
          {l}
        </a>
      ))}
    </div>
  );
}
