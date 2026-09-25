# Referencia de Instalacao

Registro tecnico completo de tudo que e instalado e configurado por este setup.
Util para entender o que cada ferramenta faz e como foi integrada.

---

## Ambiente suportado

| Sistema | Gerenciador de pacotes | Status |
|---|---|---|
| Windows 10/11 (Node + Python + Git) | — | Testado |
| Ubuntu 22+ / Debian | `apt-get` | Testado |
| Fedora 40+ | `dnf5` / `dnf` | Testado (F43) |
| RHEL / Rocky / Alma / CentOS Stream 9-10 | `dnf` | Suportado |
| macOS 13+ (Apple Silicon e Intel) | `brew` | Testado |
| WSL2 (Windows) | `apt-get` | Necessario para claude-squad |

RHEL 8 **nao** e suportado: o `python3` padrao e 3.6 e exigiria module streams.

**Versoes minimas recomendadas:**
- Node.js 18+ (testado em v24 e v26)
- npm 9+ (testado em v11 e v12)
- Python 3.10+ (testado em 3.12 e 3.14)
- git 2.40+

### Deteccao de plataforma

O `setup.sh` le `/etc/os-release` (no macOS, `uname -s`) e classifica a distro em uma familia por `ID` e `ID_LIKE`:

| Familia | Detectada por | Gerenciador |
|---|---|---|
| `rhel` | `ID`/`ID_LIKE` contem `fedora`, `rhel` ou `centos` | `dnf5` > `dnf` > `yum` |
| `debian` | `ID`/`ID_LIKE` contem `debian` ou `ubuntu` | `apt-get` |
| `brew` | `uname -s` = `Darwin` | `brew` (carrega `brew shellenv` se estiver fora do `PATH`) |
| `unknown` | nenhum dos acima | nenhum — so reporta |

```bash
./setup.sh --detect-only  # imprime OS_ID, OS_VERSION, PKG_FAMILY, PKG_MGR
./setup.sh --dry-run      # imprime todo comando sem executar
./setup.sh --yes          # nao pergunta antes de instalar dependencias

UCS_FORCE_FAMILY=debian ./setup.sh --dry-run   # simula outra familia
```

Dependencias faltando (git, Node.js, npm, tmux, pipx) sao instaladas apenas apos
confirmacao. Sem `sudo` ou em familia `unknown`, o script imprime o comando e segue.
No macOS o Homebrew e obrigatorio: sem ele, `setup.sh` e `update.sh` param com erro antes de
instalar qualquer coisa (instale em https://brew.sh).

---

## 1. GSD — Get Shit Done v1.36+

**Repositorio:** https://github.com/gsd-build/get-shit-done

**Comando de instalacao:**
```bash
npx get-shit-done-cc@latest --claude --global
```

**O que e instalado em `~/.claude/`:**
- 73 skills em `~/.claude/skills/`
- Agentes GSD em `~/.claude/agents/`
- Arquivo `~/.claude/get-shit-done`
- `~/.claude/VERSION`
- `~/.claude/package.json`
- `~/.claude/gsd-file-manifest.json`

**Hooks adicionados automaticamente ao `~/.claude/settings.json`:**

| Hook | Evento | Funcao |
|---|---|---|
| gsd-check-update.js | SessionStart | Verifica atualizacao do GSD |
| gsd-session-state.sh | SessionStart | Orienta Claude sobre estado atual |
| gsd-context-monitor.js | PostToolUse (Bash,Edit,Write,Agent,Task) | Monitora uso do contexto |
| gsd-phase-boundary.sh | PostToolUse (Write,Edit) | Detecta transicoes de fase |
| gsd-prompt-guard.js | PreToolUse (Write,Edit) | Protege contra prompt injection |
| gsd-read-guard.js | PreToolUse (Write,Edit) | Forca leitura antes de editar |
| gsd-workflow-guard.js | PreToolUse (Write,Edit) | Guarda de integridade do workflow |
| gsd-validate-commit.sh | PreToolUse (Bash) | Valida commits git |

**StatusLine configurada:**
```json
"statusLine": {
  "type": "command",
  "command": "node \"~/.claude/hooks/gsd-statusline.js\""
}
```

**Comandos disponiveis:**
```
/gsd-new-project       /gsd-discuss-phase     /gsd-plan-phase
/gsd-execute-phase     /gsd-verify-work       /gsd-ship
/gsd-quick             /gsd-next              /gsd-complete-milestone
/gsd-new-milestone     (+ 63 outros skills)
```

---

## 2. repomix

**Repositorio:** https://github.com/yamadashy/repomix

**Instalacao:**
```bash
npm install -g repomix
```

**Uso:**
```bash
npx repomix                           # empacota projeto inteiro
npx repomix --include "src/**/*.ts"   # so arquivos especificos
npx repomix --compress                # saida comprimida
```
Gera `repomix-output.xml` otimizado para IA.

---

## 3. ccusage

**Repositorio:** https://github.com/ryoppippi/ccusage

**Instalacao:**
```bash
npm install -g ccusage
```

**Uso:**
```bash
ccusage           # resumo geral
ccusage --today   # so hoje
ccusage --json    # saida JSON
```

---

## 4. task-master-ai

**Repositorio:** https://github.com/eyaltoledano/claude-task-master

**Instalacao:**
```bash
npm install -g task-master-ai
```

**Comando:** `task-master`

---

## 5. SuperClaude v4.3+

**Repositorio:** https://github.com/SuperClaude-Org/SuperClaude_Framework

**Instalacao:**
```bash
# Windows
pip install superclaude
$env:PYTHONIOENCODING = 'utf-8'   # fix de encoding para emojis
superclaude install

# Linux/Mac — pipx, nao pip
pipx install superclaude
PYTHONIOENCODING=utf-8 superclaude install
```

**Por que pipx e nao pip (PEP 668):** Fedora, RHEL e Debian modernos marcam o Python do
sistema como *externally managed* (arquivo `EXTERNALLY-MANAGED` ao lado da stdlib).
`pip install superclaude` aborta com `error: externally-managed-environment`. O `pipx`
cria um venv isolado e coloca o binario em `~/.local/bin` — e o caminho suportado pelas
distros. Em RHEL/Rocky/Alma o pacote `pipx` vem do EPEL:

```bash
sudo dnf install -y epel-release
sudo dnf install -y pipx
```

No macOS o `pipx` vem do Homebrew (`brew install pipx`); o `python3` das Xcode Command Line Tools
costuma ser 3.9, antigo demais (o SuperClaude exige 3.10+).

**Fallback automatico:** se o `pipx` nao estiver disponivel, o `setup.sh` cria
`~/.claude/venv-superclaude` com `python3 -m venv` e faz symlink do binario em
`~/.local/bin/superclaude`. O `update.sh` detecta qual dos dois caminhos foi usado.

**31 comandos instalados em `~/.claude/commands/sc/`:**
```
/agent        /analyze      /brainstorm   /build        /business-panel
/cleanup      /design       /document     /estimate     /explain
/git          /help         /implement    /improve      /index-repo
/index        /load         /pm           /README       /recommend
/reflect      /research     /save         /sc           /select-tool
/spawn        /spec-panel   /task         /test         /troubleshoot
/workflow
```

**20 agentes instalados em `~/.claude/agents/`:**
```
@backend-architect      @business-panel-experts  @deep-research-agent
@deep-research          @devops-architect        @frontend-architect
@learning-guide         @performance-engineer    @pm-agent
@python-expert          @quality-engineer        @refactoring-expert
@repo-index             @requirements-analyst    @root-cause-analyst
@security-engineer      @self-review             @socratic-mentor
@system-architect       @technical-writer
```

---

## 5b. graphify

**Repositorio:** https://github.com/Graphify-Labs/graphify
**Pacote PyPI:** `graphifyy` (o nome `graphify` esta sendo reivindicado; o CLI e a skill
continuam se chamando `graphify`)

**Instalacao:**
```bash
# Linux/Mac — pipx (PEP 668)
pipx install graphifyy
graphify install

# Windows
pip install graphifyy
graphify install
```

`graphify install` registra a skill em `~/.claude/skills/graphify/` (`SKILL.md` + `references/`)
e adiciona a linha de trigger ao `~/.claude/CLAUDE.md`. O backend Python resolve o interpretador
sozinho (uv tool, pipx, venv ou system) e grava em `graphify-out/.graphify_python`.

**Requisito extra:** Python 3.10+ — o mesmo do SuperClaude.

**Nao precisa de API key.** Codigo e extraido estruturalmente (AST), sem LLM: `/graphify .` num
repositorio de codigo nao le nenhuma chave. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` e afins nunca
sao lidos. A extracao semantica (so para docs, PDFs, papers e imagens) usa o proprio agente da
sessao como LLM; opcionalmente, se `GEMINI_API_KEY` ou `GOOGLE_API_KEY` ja estiver no ambiente,
ela usa Gemini:

```bash
pipx install 'graphifyy[gemini]'   # opcional — so para corpus com docs/imagens
export GEMINI_API_KEY=...          # opcional — sem isso, o agente extrai
```

**Uso:**
```bash
/graphify .                                    # constroi o grafo da pasta atual
/graphify query "o que conecta X a Y?"         # consulta o grafo (BFS)
/graphify path "NodeA" "NodeB"                 # menor caminho entre dois nos
/graphify explain "NomeDoNo"                   # vizinhanca de um no
/graphify . --update                           # re-extrai so arquivos alterados
```

**Saidas em `graphify-out/`:** `graph.html`, `GRAPH_REPORT.md`, `graph.json`, `obsidian/`,
`wiki/`, `cache/` (SHA256, evita reprocessar arquivo inalterado).

---

## 6. MCP Servers

MCPs ficam em `~/.claude.json` e sao gerenciados via `claude mcp add`.

**Instalacao:**
```bash
claude mcp add sequential-thinking -- npx -y "@modelcontextprotocol/server-sequential-thinking"
claude mcp add context7            -- npx -y "@upstash/context7-mcp"
claude mcp add filesystem          -- npx -y "@modelcontextprotocol/server-filesystem" "$HOME"
```

| MCP | Para que serve | Como usar |
|---|---|---|
| sequential-thinking | Raciocinio em passos logicos | Automatico em tarefas complexas |
| context7 | Docs atualizadas em tempo real | Adicione `use context7` no prompt |
| filesystem | Acesso a arquivos locais | Automatico |

---

## 7. claude-squad

**Repositorio:** https://github.com/smtg-ai/claude-squad

**Requisito:** tmux (Linux/Mac) ou WSL2 (Windows)

**Instalacao Linux/Mac:**
```bash
# Instalar tmux se necessario
brew install tmux              # macOS
sudo apt-get install -y tmux   # Ubuntu/Debian
sudo dnf install -y tmux       # Fedora/RHEL/Rocky/Alma

# Instalar claude-squad
curl -fsSL https://raw.githubusercontent.com/smtg-ai/claude-squad/main/install.sh | bash
```

O binario `cs` vai para `~/.local/bin` — garanta que esta no `PATH`.

**Instalacao Windows:**
```powershell
# PowerShell como Administrador
wsl --install
# Reiniciar o PC

# No terminal WSL2
curl -fsSL https://raw.githubusercontent.com/smtg-ai/claude-squad/main/install.sh | bash
```

**Uso:** `cs`

---

## 8. Correcoes e notas tecnicas

- **`settings.json` NAO aceita `mcpServers`** — MCPs ficam em `~/.claude.json` via `claude mcp add`
- **SuperClaude no Windows** requer `PYTHONIOENCODING=utf-8` por causa de emojis no output
- **WSL2 no Windows 10/11** requer restart apos `wsl --install` para ativar
- **PEP 668 (Fedora/RHEL/Debian)** — `pip install` no Python do sistema falha; use `pipx` (secao 5)
- **`npm install -g` com Node do gerenciador de pacotes** — o prefix e `/usr`, que nao e gravavel
  pelo usuario, e a instalacao falha com `EACCES`. O `setup.sh` detecta isso e roda
  `npm config set prefix "$HOME/.local"`. Node via nvm/fnm ja usa prefix no `$HOME` e nao e alterado.
  No macOS o mesmo vale para o Node do `.pkg` oficial (prefix `/usr/local`). A checagem olha
  `lib/node_modules` quando existe: num Mac Intel com Homebrew, `/usr/local/lib` e do usuario, mas o
  `node_modules` do `.pkg` continua do root. O Node do Homebrew nao e alterado.
- **`~/.local/bin` precisa estar no `PATH`** — destino de `pipx`, `claude-squad` (`cs`) e do npm
  reconfigurado. O script exporta na sessao atual e avisa para persistir no `.bashrc`/`.zshrc`.
  No macOS o aviso cita `~/.zshrc` (zsh e o padrao) ou `~/.bash_profile` (bash de login nao le `~/.bashrc`).
- **CLI `claude` ausente** — o script nao aborta mais; imprime os `claude mcp add` para rodar depois.
- **`~/.claude/CLAUDE.md` e sobrescrito** pelo template deste repo. Se ja existir, os scripts
  criam `CLAUDE.md.bak.AAAAMMDD-HHMMSS` antes de escrever. Reaplique suas regras customizadas.
- **`setup.ps1`: backticks no here-string** — em `@"..."@` o PowerShell trata `` ` `` como escape
  (`` `n `` virava quebra de linha no meio de `` `npx repomix` ``). Os backticks de markdown agora
  sao duplicados no script para produzir um backtick literal no arquivo final.
- **Homebrew fora do `PATH` no Apple Silicon** — `/opt/homebrew` so entra no `PATH` via `brew shellenv`.
  Se o `brew` existir em `/opt/homebrew/bin` ou `/usr/local/bin`, `setup.sh` e `update.sh` carregam o
  `brew shellenv` na sessao e avisam para persistir `eval "$(/opt/homebrew/bin/brew shellenv)"` no `~/.zprofile`.
- **Xcode Command Line Tools (CLT)** — checadas com `xcode-select -p`. Sem elas, `/usr/bin/git` e
  `/usr/bin/python3` sao stubs que so abrem o instalador grafico; o script os trata como ausentes
  (instala via `brew`) e avisa para rodar `xcode-select --install`.
- **bash 3.2 no macOS** — `setup.sh` e `update.sh` sao compativeis com o `/bin/bash` 3.2 nativo do
  macOS; nenhum recurso de bash 4+ e usado.
- **`.gitattributes` forca LF nos `*.sh`** — com CRLF, macOS e Linux falham com
  `bad interpreter: /bin/bash^M`. `setup.sh` e `update.sh` tambem sao versionados como executaveis
  (modo `100755`), entao `./setup.sh` funciona logo apos o clone; o `chmod +x` continua inofensivo.

---

## 9. Estrutura final do `~/.claude`

```
~/.claude/
├── settings.json      # hooks GSD + statusline
├── CLAUDE.md          # instrucoes globais (criado pelo setup)
├── commands/sc/       # 31 comandos SuperClaude
├── agents/            # 20 agentes SuperClaude + agentes GSD
├── skills/            # 73 skills GSD
├── hooks/             # 8 hooks GSD
└── memory/            # auto-memoria persistente do Claude Code
~/.claude.json         # MCP servers (sequential-thinking, context7, filesystem)
```
