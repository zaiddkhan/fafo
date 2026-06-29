import {
  type ButtonHTMLAttributes,
  type InputHTMLAttributes,
  type ReactNode,
  type SelectHTMLAttributes,
  type TextareaHTMLAttributes,
} from "react";

export function cn(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(" ");
}

// Shared neo-brutalist treatment (thick ink border + hard offset shadow that
// collapses on press) — matches the public site's button/card language.
const HARD =
  "border-[2.5px] border-ink shadow-[3px_3px_0_0_#16171b] active:translate-x-[3px] active:translate-y-[3px] active:shadow-none";

type Variant = "primary" | "secondary" | "danger" | "ghost" | "success";

const variantClasses: Record<Variant, string> = {
  primary: cn(HARD, "bg-brand-500 text-white"),
  secondary: cn(HARD, "bg-white text-ink"),
  danger: cn(HARD, "bg-[#E23B30] text-white"),
  success: cn(HARD, "bg-[#1FB24A] text-white"),
  ghost:
    "border-[2.5px] border-transparent text-ink/60 hover:bg-black/[0.04] hover:text-ink",
};

export function Button({
  variant = "primary",
  className,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant }) {
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center gap-1.5 rounded-xl px-4 py-2 text-sm font-bold transition-[transform,box-shadow,background-color] duration-75 disabled:cursor-not-allowed disabled:opacity-50",
        variantClasses[variant],
        className,
      )}
      {...props}
    />
  );
}

export function Card({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-2xl border-[2.5px] border-ink bg-white p-5 shadow-[5px_5px_0_0_#16171b]",
        className,
      )}
    >
      {children}
    </div>
  );
}

export function Badge({
  children,
  tone = "gray",
}: {
  children: ReactNode;
  tone?: "gray" | "green" | "amber" | "red" | "blue";
}) {
  const tones: Record<string, string> = {
    gray: "bg-[#E7E9EF] text-ink",
    green: "bg-[#1FB24A] text-white",
    amber: "bg-[#F5B301] text-ink",
    red: "bg-[#E23B30] text-white",
    blue: "bg-brand-500 text-white",
  };
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full border-2 border-ink px-2.5 py-0.5 text-xs font-extrabold",
        tones[tone],
      )}
    >
      {children}
    </span>
  );
}

const FIELD_BASE =
  "w-full rounded-xl border-[2.5px] border-ink bg-white px-3 py-2 text-sm font-medium text-ink outline-none transition-shadow placeholder:text-ink/40 focus:shadow-[3px_3px_0_0_#16171b]";

export function Input(props: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={cn(FIELD_BASE, props.className)} />;
}

export function Textarea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea {...props} className={cn(FIELD_BASE, props.className)} />;
}

export function Select(props: SelectHTMLAttributes<HTMLSelectElement>) {
  return <select {...props} className={cn(FIELD_BASE, props.className)} />;
}

export function Field({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-wide text-ink/70">
        {label}
      </span>
      {children}
      {hint && <span className="mt-1 block text-xs text-ink/50">{hint}</span>}
    </label>
  );
}

export function Spinner() {
  return (
    <div className="flex items-center justify-center py-16">
      <div className="h-7 w-7 animate-spin rounded-full border-[3px] border-ink/20 border-t-brand-500" />
    </div>
  );
}

export function EmptyState({ message }: { message: string }) {
  return (
    <div className="py-16 text-center text-sm font-semibold text-ink/50">
      {message}
    </div>
  );
}

export function ErrorState({ message }: { message: string }) {
  return (
    <div className="rounded-xl border-2 border-ink bg-[#FDE2E2] px-4 py-3 text-sm font-semibold text-[#B42318]">
      {message}
    </div>
  );
}

export function Table({ children }: { children: ReactNode }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse text-sm">{children}</table>
    </div>
  );
}

export function Th({ children }: { children: ReactNode }) {
  return (
    <th className="border-b-[2.5px] border-ink px-3 py-2.5 text-left text-xs font-extrabold uppercase tracking-wide text-ink/60">
      {children}
    </th>
  );
}

export function Td({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <td className={cn("border-b-2 border-ink/10 px-3 py-3 align-top", className)}>
      {children}
    </td>
  );
}

export function Modal({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}) {
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4"
      onClick={onClose}
    >
      <div
        className="max-h-[88vh] w-full max-w-lg overflow-y-auto rounded-2xl border-[2.5px] border-ink bg-white p-6 shadow-[8px_8px_0_0_#16171b]"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="mb-4 text-lg font-extrabold tracking-tight">{title}</h2>
        {children}
      </div>
    </div>
  );
}
