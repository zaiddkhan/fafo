// Mirrors backend app/schemas.py admin models.

export type CreatorStatus =
  | "pending"
  | "reapplied"
  | "approved"
  | "revoked"
  | "rejected";

export interface CreatorListItem {
  uid: string;
  display_name: string;
  username: string;
  photo_url?: string | null;
  status: CreatorStatus;
  is_creator: boolean;
  reapplied: boolean;
  submitted_at?: string | null;
  reviewed_at?: string | null;
}

export interface CreatorHistoryEntry {
  status: string;
  at: string;
  note?: string | null;
}

export interface CreatorDetail extends CreatorListItem {
  purpose: string;
  social_links: string[];
  relevant_links: string[];
  phone: string;
  history: CreatorHistoryEntry[];
}

export type QuestDifficulty = "easy" | "medium" | "hard";

export interface Area {
  lat: number;
  lng: number;
  radius_km: number;
}

export interface AdminQuest {
  id: string;
  title: string;
  description?: string | null;
  difficulty: QuestDifficulty;
  city?: string | null;
  area?: Area | null;
  published: boolean;
  activation_count: number;
  created_at: string;
  updated_at: string;
}

export interface Category {
  id: string;
  name: string;
  emoji: string;
  sort_order: number;
}

export interface AdminEventListItem {
  id: string;
  title: string;
  creator_uid: string;
  category_id: string;
  location_name: string;
  lat: number;
  lng: number;
  date_time: string;
  joinee_count: number;
  cancelled: boolean;
  seeded: boolean;
  created_at: string;
}

export interface LaunchArea {
  id: string;
  name: string;
  center_lat: number;
  center_lng: number;
  radius_km: number;
  created_at: string;
}

export interface ExpiringEvent {
  id: string;
  title: string;
  location_name: string;
  date_time: string;
  seeded: boolean;
}

export interface DensityArea {
  area: LaunchArea;
  active_event_count: number;
  below_threshold: boolean;
  expiring_24h: ExpiringEvent[];
}

export interface DensityResponse {
  threshold: number;
  areas: DensityArea[];
  generated_at: string;
}

export interface AdminUserListItem {
  uid: string;
  display_name: string;
  username: string;
  phone?: string | null;
  photo_url?: string | null;
  is_creator: boolean;
  deactivated: boolean;
}

export interface AdminUserGroup {
  id: string;
  name: string;
  is_admin: boolean;
}

export interface AdminUserDetail extends AdminUserListItem {
  friends_count: number;
  events_joined: number;
  current_streak: number;
  groups: AdminUserGroup[];
}

export interface NotificationTemplate {
  id: string;
  type: string;
  subtype: string;
  body: string;
  variables: string[];
  sound?: string | null;
  enabled: boolean;
  params: Record<string, unknown>;
  version: number;
  updated_at?: string | null;
  updated_by?: string | null;
}

export interface NotificationTemplateVersion {
  version: number;
  body: string;
  sound?: string | null;
  enabled: boolean;
  params: Record<string, unknown>;
  updated_at?: string | null;
  updated_by?: string | null;
}

export interface AuditLogEntry {
  id: string;
  admin_uid: string;
  action: string;
  target_type?: string | null;
  target_id?: string | null;
  reason?: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}
