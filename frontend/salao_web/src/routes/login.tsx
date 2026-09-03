import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { Eye, EyeOff, Loader2, Sparkles, TriangleAlert } from "lucide-react";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { AppEnvironment } from "@/lib/env";
import { textoDoErro, useLogin, useSessao } from "@/lib/queries";

export const Route = createFileRoute("/login")({
  head: () => ({
    meta: [
      { title: "Entrar — Thamires Beauty" },
      {
        name: "description",
        content:
          "Acesse o Thamires Beauty e acompanhe faturamento, gastos, lucro e estoque do seu salão.",
      },
      { property: "og:title", content: "Entrar — Thamires Beauty" },
      {
        property: "og:description",
        content: "Gestão financeira simples para profissionais de beleza.",
      },
    ],
  }),
  component: LoginPage,
});

function LoginPage() {
  const navigate = useNavigate();
  const { data: sessao } = useSessao();
  const login = useLogin();

  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [mostrar, setMostrar] = useState(false);

  // Quem já tem sessão não vê o login de novo — inclusive depois de um F5.
  useEffect(() => {
    if (sessao) void navigate({ to: "/", replace: true });
  }, [sessao, navigate]);

  function entrar(e: React.FormEvent) {
    e.preventDefault();
    login.mutate(
      { email: email.trim(), senha },
      { onSuccess: () => void navigate({ to: "/", replace: true }) },
    );
  }

  return (
    <div className="grid min-h-screen lg:grid-cols-[1.05fr_1fr]">
      <div className="relative hidden flex-col justify-between overflow-hidden bg-brand-gradient p-12 text-primary-foreground lg:flex">
        <div className="flex items-center gap-3">
          <span className="grid size-11 place-items-center rounded-2xl bg-surface/20">
            <Sparkles className="size-5" />
          </span>
          <span className="font-display text-xl font-semibold">Thamires Beauty</span>
        </div>
        <div className="max-w-md">
          <h2 className="font-display text-4xl leading-tight font-semibold">
            Saiba em segundos se o mês está dando lucro.
          </h2>
          <p className="mt-4 text-sm/relaxed text-primary-foreground/85">
            Atendimentos, gastos, estoque e kits de revenda em um só lugar — feito para o dia a dia
            do salão.
          </p>
        </div>
        <p className="text-xs text-primary-foreground/70">
          Faturamento • Gastos • Lucro • Estoque saudável
        </p>
        <div className="pointer-events-none absolute -right-24 -bottom-32 size-80 rounded-full bg-surface/10" />
      </div>

      <div className="flex items-center justify-center bg-background px-5 py-14">
        <div className="w-full max-w-sm">
          <div className="mb-8 text-center lg:hidden">
            <span className="mx-auto grid size-14 place-items-center rounded-2xl bg-brand-gradient text-primary-foreground shadow-glow">
              <Sparkles className="size-6" />
            </span>
            <h1 className="mt-4 font-display text-2xl font-semibold">Thamires Beauty</h1>
            <p className="mt-1 text-sm text-muted-foreground">Gestão financeira do seu salão</p>
          </div>

          <h2 className="hidden font-display text-2xl font-semibold lg:block">
            Bem-vinda de volta
          </h2>
          <p className="hidden text-sm text-muted-foreground lg:mt-1 lg:block">
            Entre para ver como está o seu mês.
          </p>

          {/*
            Sem este aviso a demo é indistinguível do app real, e alguém salva um
            dado achando que ficou gravado.
          */}
          {AppEnvironment.isDemo ? (
            <p className="mt-6 flex items-start gap-2 rounded-xl border border-warning/25 bg-warning-soft px-3 py-2.5 text-xs text-warning">
              <TriangleAlert className="mt-px size-4 shrink-0" />
              <span>
                <strong className="font-semibold">Modo demonstração.</strong> Os dados são de
                exemplo e somem quando você fecha a aba. Entre com qualquer e-mail e senha.
              </span>
            </p>
          ) : null}

          <form onSubmit={entrar} className="mt-6 space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="email">E-mail</Label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="h-12 rounded-xl"
                required
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="senha">Senha</Label>
              <div className="relative">
                <Input
                  id="senha"
                  type={mostrar ? "text" : "password"}
                  autoComplete="current-password"
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
                  className="h-12 rounded-xl pr-12"
                  placeholder="Digite sua senha"
                  required
                />
                <button
                  type="button"
                  onClick={() => setMostrar((v) => !v)}
                  aria-label={mostrar ? "Ocultar senha" : "Mostrar senha"}
                  className="absolute inset-y-0 right-0 grid w-12 place-items-center text-muted-foreground hover:text-foreground"
                >
                  {mostrar ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </div>

            {login.isError ? (
              <p
                role="alert"
                className="rounded-xl border border-negative-mid/60 bg-negative-soft px-3 py-2.5 text-sm text-negative"
              >
                {textoDoErro(login.error)}
              </p>
            ) : null}

            <Button
              type="submit"
              className="h-12 w-full rounded-xl text-base"
              disabled={login.isPending}
            >
              {login.isPending ? (
                <>
                  <Loader2 className="size-4 animate-spin" />
                  Entrando...
                </>
              ) : (
                "Entrar"
              )}
            </Button>
          </form>
        </div>
      </div>
    </div>
  );
}
