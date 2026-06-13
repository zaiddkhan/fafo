import { useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { track } from "@/lib/analytics";
import type { AdminUserDetail, AdminUserListItem } from "@/lib/types";
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
  Table,
  Td,
  Textarea,
  Th,
} from "@/components/ui";

const USERNAME_RE = /^[a-z0-9._]+$/;

export function UserManagementPage() {
  const [term, setTerm] = useState("");
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState<string | null>(null);

  const { data, isLoading, error, isFetching } = useQuery({
    queryKey: ["user-search", query],
    queryFn: () =>
      api<AdminUserListItem[]>("/admin/users/search", { query: { q: query } }),
    enabled: query.length > 0,
  });

  function onSubmit(e: FormEvent) {
    e.preventDefault();
    setQuery(term.trim());
  }

  return (
    <>
      <PageHeader
        title="User Management"
        subtitle="Search for a user, then take targeted administrative actions."
      />
      <Card>
        <form onSubmit={onSubmit} className="mb-4 flex gap-2">
          <Input
            placeholder="Search by username, name, or phone"
            value={term}
            onChange={(e) => setTerm(e.target.value)}
          />
          <Button type="submit" className="flex-shrink-0">
            Search
          </Button>
        </form>

        {query.length === 0 ? (
          <EmptyState message="Search for a user by username, name, or phone." />
        ) : isLoading || isFetching ? (
          <Spinner />
        ) : error ? (
          <ErrorState message={(error as Error).message} />
        ) : !data || data.length === 0 ? (
          <EmptyState message="No users matched that search." />
        ) : (
          <Table>
            <thead>
              <tr>
                <Th>User</Th>
                <Th>Phone</Th>
                <Th>Status</Th>
                <Th>Action</Th>
              </tr>
            </thead>
            <tbody>
              {data.map((u) => (
                <tr key={u.uid}>
                  <Td>
                    <div className="font-semibold">{u.display_name}</div>
                    <div className="text-xs text-gray-400">
                      {u.username ? `@${u.username}` : u.uid}
                    </div>
                  </Td>
                  <Td className="text-gray-500">{u.phone || "—"}</Td>
                  <Td>
                    <div className="flex items-center gap-2">
                      {u.is_creator && <Badge tone="blue">Creator</Badge>}
                      {u.deactivated && <Badge tone="red">Deactivated</Badge>}
                    </div>
                  </Td>
                  <Td>
                    <Button variant="secondary" onClick={() => setSelected(u.uid)}>
                      View
                    </Button>
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        )}
      </Card>

      {selected && (
        <UserDetailModal uid={selected} onClose={() => setSelected(null)} />
      )}
    </>
  );
}

function UserDetailModal({
  uid,
  onClose,
}: {
  uid: string;
  onClose: () => void;
}) {
  const { data, isLoading } = useQuery({
    queryKey: ["user", uid],
    queryFn: () => api<AdminUserDetail>(`/admin/users/${uid}`),
  });

  return (
    <Modal open onClose={onClose} title="User detail">
      {isLoading || !data ? (
        <Spinner />
      ) : (
        <div className="space-y-4">
          <div>
            <div className="text-lg font-bold">{data.display_name}</div>
            <div className="text-sm text-gray-400">
              {data.username ? `@${data.username}` : data.uid} ·{" "}
              {data.phone || "—"}
            </div>
            <div className="mt-2 flex gap-2">
              {data.is_creator && <Badge tone="blue">Creator</Badge>}
              {data.deactivated && <Badge tone="red">Deactivated</Badge>}
            </div>
          </div>

          <Section label="Stats">
            <div className="grid grid-cols-3 gap-3 text-sm">
              <Stat label="Friends" value={data.friends_count} />
              <Stat label="Events joined" value={data.events_joined} />
              <Stat label="Current streak" value={data.current_streak} />
            </div>
          </Section>

          <Section label="Groups">
            {data.groups.length === 0 ? (
              <span className="text-sm text-gray-400">—</span>
            ) : (
              <ul className="space-y-1 text-sm text-gray-700">
                {data.groups.map((g) => (
                  <li key={g.id} className="flex items-center gap-2">
                    <span>{g.name}</span>
                    {g.is_admin && <Badge tone="blue">admin</Badge>}
                  </li>
                ))}
              </ul>
            )}
          </Section>

          <div className="space-y-3 border-t border-gray-100 pt-4">
            {data.is_creator && <RevokeCreatorForm uid={uid} />}
            <ForceUsernameForm uid={uid} />
            {!data.deactivated && (
              <DeactivateForm uid={uid} onClose={onClose} />
            )}
          </div>

          <div className="flex justify-end pt-2">
            <Button variant="ghost" onClick={onClose}>
              Close
            </Button>
          </div>
        </div>
      )}
    </Modal>
  );
}

function useUserAction(uid: string, onDone?: () => void) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      action,
      body,
    }: {
      action: string;
      body: Record<string, string>;
    }) => api(`/admin/users/${uid}/${action}`, { method: "POST", body }),
    onSuccess: (_d, { action }) => {
      track("admin_user_action", { action, uid });
      qc.invalidateQueries({ queryKey: ["user", uid] });
      qc.invalidateQueries({ queryKey: ["user-search"] });
      onDone?.();
    },
  });
}

function RevokeCreatorForm({ uid }: { uid: string }) {
  const [reason, setReason] = useState("");
  const m = useUserAction(uid, () => setReason(""));
  const valid = reason.trim().length >= 3;

  return (
    <ActionSection title="Revoke creator status">
      <Field label="Reason" hint="Required, minimum 3 characters.">
        <Textarea
          rows={2}
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          placeholder="Why is creator status being revoked?"
        />
      </Field>
      {m.error && <ErrorState message={(m.error as Error).message} />}
      {m.isSuccess && (
        <div className="text-xs font-semibold text-green-700">
          Creator status revoked.
        </div>
      )}
      <div className="flex justify-end">
        <Button
          variant="danger"
          disabled={!valid || m.isPending}
          onClick={() =>
            m.mutate({ action: "revoke-creator", body: { reason: reason.trim() } })
          }
        >
          Revoke creator
        </Button>
      </div>
    </ActionSection>
  );
}

function ForceUsernameForm({ uid }: { uid: string }) {
  const [newUsername, setNewUsername] = useState("");
  const [reason, setReason] = useState("");
  const m = useUserAction(uid, () => {
    setNewUsername("");
    setReason("");
  });

  const usernameValid =
    newUsername.length >= 3 &&
    newUsername.length <= 30 &&
    USERNAME_RE.test(newUsername);
  const reasonValid = reason.trim().length >= 3;
  const valid = usernameValid && reasonValid;

  return (
    <ActionSection title="Force username change">
      <Field
        label="New username"
        hint="3–30 chars, lowercase letters, digits, dots, and underscores only."
      >
        <Input
          value={newUsername}
          onChange={(e) => setNewUsername(e.target.value)}
          placeholder="new_username"
        />
      </Field>
      <Field label="Reason" hint="Required, minimum 3 characters.">
        <Textarea
          rows={2}
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          placeholder="Why is the username being changed?"
        />
      </Field>
      {m.error && <ErrorState message={(m.error as Error).message} />}
      {m.isSuccess && (
        <div className="text-xs font-semibold text-green-700">
          Username changed.
        </div>
      )}
      <div className="flex justify-end">
        <Button
          variant="danger"
          disabled={!valid || m.isPending}
          onClick={() =>
            m.mutate({
              action: "force-username",
              body: { new_username: newUsername, reason: reason.trim() },
            })
          }
        >
          Force change
        </Button>
      </div>
    </ActionSection>
  );
}

function DeactivateForm({
  uid,
  onClose,
}: {
  uid: string;
  onClose: () => void;
}) {
  const [reason, setReason] = useState("");
  const m = useUserAction(uid, onClose);
  const valid = reason.trim().length >= 3;

  return (
    <ActionSection title="Deactivate account">
      <p className="text-xs text-gray-500">
        Hides the profile and expires active nudge cards. Data is retained.
      </p>
      <Field label="Reason" hint="Required, minimum 3 characters.">
        <Textarea
          rows={2}
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          placeholder="Why is this account being deactivated?"
        />
      </Field>
      {m.error && <ErrorState message={(m.error as Error).message} />}
      <div className="flex justify-end">
        <Button
          variant="danger"
          disabled={!valid || m.isPending}
          onClick={() =>
            m.mutate({ action: "deactivate", body: { reason: reason.trim() } })
          }
        >
          Deactivate
        </Button>
      </div>
    </ActionSection>
  );
}

function ActionSection({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-2 rounded-xl border border-gray-200 p-3">
      <div className="text-sm font-bold text-gray-800">{title}</div>
      {children}
    </div>
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

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-lg bg-gray-50 px-3 py-2">
      <div className="text-lg font-bold text-gray-900">{value}</div>
      <div className="text-xs text-gray-500">{label}</div>
    </div>
  );
}
