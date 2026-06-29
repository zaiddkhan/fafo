import { useState } from "react";
import { useAuth } from "./AuthProvider";
import { Button, Card, Field, Input } from "@admin/components/ui";

export function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await login(email, password);
    } catch (err) {
      const code = (err as { code?: string }).code ?? "";
      if (code === "auth/operation-not-allowed") {
        setError(
          "Email/Password sign-in is disabled for this Firebase project. Enable it in Firebase console → Authentication → Sign-in method.",
        );
      } else if (
        code === "auth/invalid-credential" ||
        code === "auth/wrong-password" ||
        code === "auth/user-not-found"
      ) {
        setError("Invalid email or password.");
      } else {
        setError(`Sign-in failed: ${code || (err as Error).message}`);
      }
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <div className="mb-4 flex items-center gap-2">
          <span className="grid h-9 w-9 place-items-center rounded-lg border-2 border-ink bg-brand-500 text-base font-extrabold text-white shadow-[2px_2px_0_0_#16171b]">
            F
          </span>
          <h1 className="text-xl font-extrabold tracking-tight text-ink">
            Fafo Admin
          </h1>
        </div>
        <p className="mb-5 text-sm font-medium text-ink/60">
          Sign in with your admin account.
        </p>
        <form onSubmit={submit} className="space-y-4">
          <Field label="Email">
            <Input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoFocus
              required
            />
          </Field>
          <Field label="Password">
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </Field>
          {error && (
            <p className="text-sm font-semibold text-[#B42318]">{error}</p>
          )}
          <Button type="submit" disabled={busy} className="w-full">
            {busy ? "Signing in…" : "Sign in"}
          </Button>
        </form>
      </Card>
    </div>
  );
}
