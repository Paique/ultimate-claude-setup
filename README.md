# Claude Code Setup PT-BR

> Curadoria e instalacao automatizada das melhores ferramentas open source para Claude Code.
> Um comando instala tudo. Focado na comunidade brasileira de desenvolvimento.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Plataformas](https://img.shields.io/badge/plataformas-Windows%20%7C%20Linux%20%7C%20macOS-blue)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-blueviolet)](https://claude.ai/code)
[![PT-BR](https://img.shields.io/badge/idioma-PT--BR-green)]()

> **Aviso:** Este projeto e uma curadoria e script de automacao de instalacao.
> Nao somos afiliados a Anthropic nem aos projetos incluidos.
> Todo o credito vai para os autores originais — veja [CREDITS.md](CREDITS.md).

---

## Por que este projeto existe?

Configurar o Claude Code com todas as melhores ferramentas da comunidade leva horas de pesquisa e instalacao manual. Este projeto resolve isso com um unico comando, documentacao completa em PT-BR e curadoria das ferramentas mais impactantes.

**O que este projeto oferece:**
- Script de instalacao automatica (Windows + Linux + macOS)
- Documentacao completa em portugues de cada ferramenta
- Curadoria das ferramentas com maior impacto real no workflow
- Guia de uso de agentes e comandos com exemplos praticos

---

## Estatisticas das ferramentas incluidas

| Ferramenta | Stars | Forks | O que faz |
|---|---|---|---|
| [GSD](https://github.com/gsd-build/get-shit-done) | ⭐ 53k+ | 🍴 4.5k | Workflow spec-driven, previne context rot |
| [SuperClaude](https://github.com/SuperClaude-Org/SuperClaude_Framework) | ⭐ 20k+ | 🍴 2k | 31 comandos + 20 agentes especializados |
| [repomix](https://github.com/yamadashy/repomix) | ⭐ 20k+ | 🍴 1k | Empacota codebase para IA, economiza tokens |
| [task-master](https://github.com/eyaltoledano/claude-task-master) | ⭐ 20k+ | 🍴 2k | Gerenciamento de tarefas com IA |
| [claude-squad](https://github.com/smtg-ai/claude-squad) | ⭐ 8k+ | 🍴 500 | Multi-agente paralelo com tmux |
| [graphify](https://github.com/Graphify-Labs/graphify) | — | — | Codebase vira grafo de conhecimento consultavel |
| [ccusage](https://github.com/ryoppippi/ccusage) | ⭐ 3k+ | 🍴 200 | Dashboard de consumo de tokens |
| [context7 MCP](https://github.com/upstash/context7) | ⭐ 15k+ | 🍴 800 | Docs atualizadas em tempo real |
| [MCP Servers](https://github.com/modelcontextprotocol/servers) | ⭐ 14k+ | 🍴 1.5k | Sequential thinking + filesystem |
| [Frontend Design Plugin](https://claude.com/plugins/frontend-design) | oficial | — | UI distintiva, sem AI slop |

**Total de stars curadas: ~153k+** — o melhor do ecossistema Claude Code em um lugar so.

---

## Instalacao — 1 comando

**Pre-requisitos:** [Node.js 18+](https://nodejs.org) · [Python 3.10+](https://python.org) · [git](https://git-scm.com) · [Claude Code CLI](https://claude.ai/code)

```bash
git clone https://github.com/FalvesDev/ultimate-claude-setup.git
cd ultimate-claude-setup
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

**Linux / macOS / WSL2:**
```bash
chmod +x setup.sh && ./setup.sh
```

Reinicie o Claude Code apos a instalacao. Pronto.

> **Atencao:** o setup **sobrescreve** o seu `~/.claude/CLAUDE.md` com o template deste repo.
> Se o arquivo ja existir, um backup datado (`CLAUDE.md.bak.AAAAMMDD-HHMMSS`) e criado antes —
> reaplique suas regras customizadas depois.

### Distros suportadas

O `setup.sh` detecta a distro por `/etc/os-release` (no macOS, por `uname -s`) e usa o gerenciador de pacotes certo.

| Sistema | Gerenciador | Status |
|---|---|---|
| Fedora 40+ | `dnf5` / `dnf` | Suportado |
| RHEL / Rocky / Alma / CentOS Stream 9-10 | `dnf` | Suportado |
| Ubuntu 22+ / Debian | `apt-get` | Suportado |
| macOS 13+ (Apple Silicon e Intel) | `brew` | Suportado |
| Outras | — | Roda, mas so reporta dependencias faltando |

Se faltar alguma dependencia (git, Node.js, tmux, pipx), o script **mostra o comando exato
e pede confirmacao** antes de rodar `sudo`. No macOS usa `brew`, sem `sudo`, e o Homebrew e
obrigatorio. Nada e instalado sem seu aval.

**Flags uteis:**
```bash
./setup.sh --dry-run      # mostra tudo que seria executado, sem executar
./setup.sh --detect-only  # so imprime a plataforma detectada
./setup.sh --yes          # instala dependencias faltando sem perguntar
```

> **Fedora / RHEL:** o Python do sistema e marcado como `externally-managed` (PEP 668),
> entao `pip install` falha. O script instala o SuperClaude via **pipx** — com fallback
> automatico para um venv em `~/.claude/venv-superclaude`.
> Em RHEL/Rocky/Alma o `pipx` vem do EPEL: `sudo dnf install -y epel-release`.

> **macOS:** os scripts rodam no bash 3.2 nativo e exigem o [Homebrew](https://brew.sh) — sem ele,
> `setup.sh` e `update.sh` param com erro antes de instalar qualquer coisa. Sem as Xcode Command Line
> Tools, `/usr/bin/git` e `/usr/bin/python3` sao stubs que so abrem o instalador grafico: o script os
> trata como ausentes e sugere `xcode-select --install`.
> No Apple Silicon o Homebrew fica em `/opt/homebrew`, fora do `PATH` padrao: os scripts carregam o
> `brew shellenv` na sessao — persista com `eval "$(/opt/homebrew/bin/brew shellenv)"` no `~/.zprofile`.

---

## O que e instalado automaticamente

### GSD — Get Shit Done
**[github.com/gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)** · ⭐ 53k+

O sistema mais importante do setup. Resolve o maior problema do Claude Code: **context rot** — degradacao da qualidade conforme o contexto enche. Divide o trabalho em fases com contexto fresco a cada execucao.

Instala automaticamente 8 hooks, 73 skills e statusline customizada.

```
/gsd-new-project        → cria PROJECT.md, REQUIREMENTS.md, ROADMAP.md
/gsd-plan-phase 1       → pesquisa + plano detalhado
/gsd-execute-phase 1    → executa em ondas paralelas
/gsd-verify-work 1      → verifica contra os objetivos
/gsd-ship 1             → cria PR
/gsd-quick "tarefa"     → tarefa rapida sem overhead
```

---

### SuperClaude Framework
**[github.com/SuperClaude-Org/SuperClaude_Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework)** · ⭐ 20k+

Adiciona 31 comandos `/sc:` e 20 agentes especializados ao Claude Code.

**Comandos:**
```bash
/sc:implement "adicionar autenticacao JWT"
/sc:research  "melhores praticas para rate limiting"
/sc:analyze   src/auth/middleware.ts
/sc:test      src/services/userService.ts
/sc:troubleshoot "erro 500 no login OAuth"
/sc:design    "arquitetura de microservicos"
/sc:document  src/api/
```

**Agentes — use com `@nome`:**
```bash
@backend-architect     @frontend-architect    @security-engineer
@performance-engineer  @quality-engineer      @devops-architect
@python-expert         @refactoring-expert    @root-cause-analyst
@technical-writer      @deep-research-agent   @system-architect
@socratic-mentor       @requirements-analyst  @self-review
```

---

### claude-squad — Multi-agente paralelo
**[github.com/smtg-ai/claude-squad](https://github.com/smtg-ai/claude-squad)** · ⭐ 8k+

Gerencia multiplas instancias do Claude Code ao mesmo tempo, cada uma com workspace git isolado.

> Windows: requer WSL2 (`wsl --install` no PowerShell Admin + restart).
> O script detecta e instala automaticamente.

```bash
cs   # abre o painel

# Atalhos:
# n        → nova sessao
# j/k ↑↓  → navegar
# Enter    → entrar na sessao
# s        → commit + push
# D        → deletar
```

**Exemplo — 3 agentes em paralelo:**
```
→ n → "backend"  → "CRUD de usuarios com FastAPI"
→ n → "frontend" → "tela de usuarios com Next.js"
→ n → "tests"    → "testes para a API de usuarios"
# Todos rodam ao mesmo tempo!
```

---

### graphify — codebase vira grafo de conhecimento
**[github.com/Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify)**

Le uma pasta inteira — codigo, PDFs, markdown, imagens, diagramas, videos — e monta um grafo
de conhecimento persistente com deteccao de comunidades e god nodes. Depois voce **consulta o
grafo** em vez de reler os arquivos: ~71x menos tokens por pergunta, e o grafo sobrevive entre
sessoes.

```bash
/graphify .                          # constroi o grafo da pasta atual
/graphify query "o que conecta o auth ao billing?"
/graphify path "UserService" "Invoice"
/graphify explain "PaymentGateway"
/graphify . --update                 # re-extrai so o que mudou
```

Saidas em `graphify-out/`: `graph.html` interativo, `GRAPH_REPORT.md` em linguagem simples,
`graph.json` para GraphRAG, vault Obsidian e wiki navegavel por agentes.

O setup instala o pacote PyPI `graphifyy` e roda `graphify install`, que registra a skill em
`~/.claude/skills/graphify/`.

---

### repomix
**[github.com/yamadashy/repomix](https://github.com/yamadashy/repomix)** · ⭐ 20k+

Empacota toda a codebase num arquivo otimizado para IA. Reduz drasticamente o uso de tokens.

```bash
npx repomix                          # projeto inteiro
npx repomix --include "src/**/*.ts"  # so o que importa
npx repomix --compress               # ainda menor
```

---

### MCP Servers

**context7** — docs sempre atualizadas:
```bash
"como usar App Router do Next.js 15? use context7"
```

**sequential-thinking** — ativa automaticamente em tarefas complexas.

**Adicionar mais MCPs quando precisar:**
```bash
claude mcp add github   -- npx -y "@modelcontextprotocol/server-github"
claude mcp add postgres -- npx -y "@modelcontextprotocol/server-postgres" "postgresql://..."
claude mcp list
```

---

### Frontend Design Plugin
**[claude.com/plugins/frontend-design](https://claude.com/plugins/frontend-design)** · oficial Anthropic · 500k+ installs

Plugin oficial da Anthropic que transforma o Claude num designer de UI de alto nivel. Ativa automaticamente em qualquer pedido de interface frontend, forcando escolhas visuais distintas e evitando a estetica generica de "AI slop".

**Nao usa:** Inter, Roboto, gradiente roxo em fundo branco, layouts previsivos.
**Usa:** Tipografia distinta, CSS vars coesos, animacoes, composicao espacial inesperada.

```bash
# Instalado automaticamente pelo setup. Para instalar manualmente:
claude plugins install frontend-design

# Uso: apenas descreva a interface que quer
"Crie uma landing page para um SaaS de monitoramento"
"Construa um dashboard com tema escuro"
"Faca um card de produto com animacoes"
```

> Dica: use **Shift+Tab** antes de pedir uma UI para entrar no modo de planejamento e revisar a direcao estetica antes do Claude escrever o codigo.

---

## Dicas para economizar tokens

| Tecnica | Economia estimada | Como usar |
|---|---|---|
| repomix | 40-60% em contexto | `npx repomix` antes de iniciar |
| context7 MCP | Elimina docs de memoria | Adicione `use context7` no prompt |
| GSD wave execution | 30-50% em sessoes longas | Usar `/gsd-execute-phase` |
| `/gsd-quick` | Sem overhead de planejamento | Tarefas simples e rapidas |
| CLAUDE.md por projeto | Claude nao precisa perguntar | Arquivo na raiz do projeto |

---

## CLAUDE.md — template para seu projeto

Crie na raiz de cada projeto. Claude le automaticamente a cada sessao:

```markdown
# Nome do Projeto

## Stack
- Backend: FastAPI + PostgreSQL
- Frontend: Next.js 15 + Tailwind
- Deploy: Railway + Vercel

## Comandos
- `npm run dev`   → dev server
- `npm test`      → testes
- `npm run lint`  → lint + format

## Convencoes
- Commits em ingles: feat/fix/docs/refactor
- camelCase para variaveis, UPPER_SNAKE para constantes
- Testes obrigatorios para nova logica de negocio
```

---

## Estrutura apos o setup

```
~/.claude/
├── settings.json      # hooks GSD + statusline + plugins
├── CLAUDE.md          # instrucoes globais
├── commands/sc/       # 31 comandos SuperClaude
├── agents/            # 20 agentes SuperClaude + GSD
├── skills/            # 81 skills GSD
├── hooks/             # hooks GSD (context monitor, guards, etc.)
├── plugins/           # frontend-design plugin
└── memory/            # auto-memoria do Claude Code
~/.claude.json         # MCP servers (context7, sequential-thinking, filesystem)
```

---

## Atualizando

```bash
# GSD
npx get-shit-done-cc@latest --claude --global

# SuperClaude (Windows)
pip install --upgrade superclaude
$env:PYTHONIOENCODING='utf-8'; superclaude install

# SuperClaude (Linux/Mac)
pipx upgrade superclaude
PYTHONIOENCODING=utf-8 superclaude install
```

Ou simplesmente: `./update.sh` — atualiza tudo e escolhe o caminho certo (pipx ou venv).

---

## Contribuindo

Encontrou uma ferramenta que deveria estar aqui? Abra uma **issue** ou **PR**!

Por favor inclua:
- Link do repositorio original
- O que a ferramenta faz e por que merece estar no setup
- Como instalar

---

## Creditos

Todo o credito vai para os criadores das ferramentas originais.
Veja [CREDITS.md](CREDITS.md) para a lista completa com links.

---

## Documentacao

- [docs/ultimate-claude.md](docs/ultimate-claude.md) — guia completo de uso de todos os comandos e agentes
- [docs/INSTALL_LOG.md](docs/INSTALL_LOG.md) — referencia tecnica da instalacao

Este projeto contribui com: scripts de automacao, curadoria, documentacao em PT-BR.

---

## Licenca

MIT — use, modifique e distribua livremente. Veja [LICENSE](LICENSE).
