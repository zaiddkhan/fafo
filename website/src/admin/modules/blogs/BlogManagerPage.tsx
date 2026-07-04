import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@admin/lib/api";
import { track } from "@admin/lib/analytics";
import type { Blog } from "@admin/lib/types";
import { PageHeader } from "@admin/components/Layout";
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
} from "@admin/components/ui";
import { formatDate } from "@admin/lib/format";

const DEFAULT_CITY = "Bangalore";

interface BlogPayload {
  city: string;
  title: string;
  subtitle?: string;
  body: string;
  image_url?: string;
  read_time?: string;
  published: boolean;
}

export function BlogManagerPage() {
  // `city` is the loaded query; `cityInput` is the pending text-box value.
  const [cityInput, setCityInput] = useState(DEFAULT_CITY);
  const [city, setCity] = useState(DEFAULT_CITY);
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<Blog | null>(null);

  const qc = useQueryClient();
  const { data, isLoading, error } = useQuery({
    queryKey: ["blogs", city],
    queryFn: () => api<Blog[]>("/blogs", { query: { city, limit: 50 } }),
  });

  const remove = useMutation({
    mutationFn: (id: string) =>
      api(`/blogs/admin/${id}`, { method: "DELETE" }),
    onSuccess: (_d, id) => {
      track("admin_blog_deleted", { id });
      qc.invalidateQueries({ queryKey: ["blogs"] });
    },
  });

  function handleLoad() {
    const next = cityInput.trim();
    if (next !== "") setCity(next);
  }

  return (
    <>
      <PageHeader
        title="City Reads"
        subtitle="Manage the City Reads blogs shown to users per city. Note: this list only shows published blogs, so unpublished drafts won't appear here."
        action={<Button onClick={() => setCreating(true)}>New blog</Button>}
      />

      <Card className="mb-6">
        <div className="flex items-end gap-3">
          <div className="flex-1">
            <Field label="City" hint="Load published blogs for this city.">
              <Input
                value={cityInput}
                onChange={(e) => setCityInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") handleLoad();
                }}
                placeholder={DEFAULT_CITY}
              />
            </Field>
          </div>
          <Button variant="secondary" onClick={handleLoad}>
            Load
          </Button>
        </div>
      </Card>

      <Card>
        {isLoading ? (
          <Spinner />
        ) : error ? (
          <ErrorState message={(error as Error).message} />
        ) : !data || data.length === 0 ? (
          <EmptyState
            message={`No published blogs for ${city}. Create one to get started.`}
          />
        ) : (
          <Table>
            <thead>
              <tr>
                <Th>Title</Th>
                <Th>State</Th>
                <Th>Read time</Th>
                <Th>Updated</Th>
                <Th>Actions</Th>
              </tr>
            </thead>
            <tbody>
              {data.map((b) => (
                <tr key={b.id}>
                  <Td>
                    <div className="font-semibold">{b.title}</div>
                    {b.subtitle && (
                      <div className="mt-0.5 text-sm text-ink/60">
                        {b.subtitle}
                      </div>
                    )}
                  </Td>
                  <Td>
                    <Badge tone={b.published ? "green" : "gray"}>
                      {b.published ? "Published" : "Draft"}
                    </Badge>
                  </Td>
                  <Td className="text-ink/60">{b.read_time || "—"}</Td>
                  <Td className="text-ink/60">{formatDate(b.updated_at)}</Td>
                  <Td>
                    <div className="flex gap-2">
                      <Button
                        variant="secondary"
                        onClick={() => setEditing(b)}
                      >
                        Edit
                      </Button>
                      <Button
                        variant="danger"
                        disabled={remove.isPending}
                        onClick={() => {
                          if (
                            window.confirm(
                              `Delete "${b.title}"? This cannot be undone.`,
                            )
                          ) {
                            remove.mutate(b.id);
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
        {remove.error && (
          <div className="mt-4">
            <ErrorState message={(remove.error as Error).message} />
          </div>
        )}
      </Card>

      {creating && (
        <BlogFormModal
          defaultCity={city}
          onClose={() => setCreating(false)}
        />
      )}
      {editing && (
        <BlogFormModal blog={editing} onClose={() => setEditing(null)} />
      )}
    </>
  );
}

function BlogFormModal({
  blog,
  defaultCity,
  onClose,
}: {
  blog?: Blog;
  defaultCity?: string;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const isEdit = blog !== undefined;

  const [city, setCity] = useState(blog?.city ?? defaultCity ?? DEFAULT_CITY);
  const [title, setTitle] = useState(blog?.title ?? "");
  const [subtitle, setSubtitle] = useState(blog?.subtitle ?? "");
  const [imageUrl, setImageUrl] = useState(blog?.image_url ?? "");
  const [readTime, setReadTime] = useState(blog?.read_time ?? "");
  const [body, setBody] = useState(blog?.body ?? "");
  const [published, setPublished] = useState(blog?.published ?? true);

  const save = useMutation({
    mutationFn: (payload: BlogPayload) =>
      isEdit
        ? api<Blog>(`/blogs/admin/${blog.id}`, { method: "PUT", body: payload })
        : api<Blog>("/blogs/admin", { method: "POST", body: payload }),
    onSuccess: (saved) => {
      track(isEdit ? "admin_blog_updated" : "admin_blog_created", {
        id: saved.id,
        published: saved.published,
      });
      qc.invalidateQueries({ queryKey: ["blogs"] });
      onClose();
    },
  });

  const trimmedCity = city.trim();
  const trimmedTitle = title.trim();
  const trimmedBody = body.trim();
  const canSubmit =
    trimmedCity !== "" && trimmedTitle !== "" && trimmedBody !== "";

  function handleSubmit() {
    if (!canSubmit) return;
    const payload: BlogPayload = {
      city: trimmedCity,
      title: trimmedTitle,
      body: trimmedBody,
      published,
    };
    const subtitle_ = subtitle.trim();
    const imageUrl_ = imageUrl.trim();
    const readTime_ = readTime.trim();
    if (subtitle_) payload.subtitle = subtitle_;
    if (imageUrl_) payload.image_url = imageUrl_;
    if (readTime_) payload.read_time = readTime_;
    save.mutate(payload);
  }

  return (
    <Modal open onClose={onClose} title={isEdit ? "Edit blog" : "New blog"}>
      <div className="space-y-4">
        <Field label="City" hint="Blog shows to users in this city.">
          <Input
            value={city}
            onChange={(e) => setCity(e.target.value)}
            placeholder={DEFAULT_CITY}
          />
        </Field>

        <Field label="Title">
          <Input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="The best rooftop bars in town"
          />
        </Field>

        <Field label="Subtitle" hint="Optional">
          <Input
            value={subtitle}
            onChange={(e) => setSubtitle(e.target.value)}
          />
        </Field>

        <Field label="Image URL" hint="Optional cover image.">
          <Input
            value={imageUrl}
            onChange={(e) => setImageUrl(e.target.value)}
            placeholder="https://…"
          />
        </Field>

        <Field label="Read time" hint="Optional, e.g. '5 min read'.">
          <Input
            value={readTime}
            onChange={(e) => setReadTime(e.target.value)}
            placeholder="5 min read"
          />
        </Field>

        <Field label="Body" hint="Markdown supported.">
          <Textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            rows={10}
            className="font-mono text-xs"
            placeholder="Write the article in Markdown…"
          />
        </Field>

        <label className="flex items-center gap-2 text-sm font-semibold text-ink/70">
          <input
            type="checkbox"
            checked={published}
            onChange={(e) => setPublished(e.target.checked)}
            className="h-4 w-4 rounded border-gray-300 text-brand-500 focus:ring-brand-100"
          />
          Published (unpublished drafts won't appear in the list)
        </label>

        {save.error && <ErrorState message={(save.error as Error).message} />}

        <div className="flex justify-end gap-2 pt-2">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={!canSubmit || save.isPending}
            onClick={handleSubmit}
          >
            {isEdit ? "Save changes" : "Create blog"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
