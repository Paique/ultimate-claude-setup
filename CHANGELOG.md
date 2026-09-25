# Changelog

## [Unreleased]

### Adicionado
- Checagem das Xcode Command Line Tools via `xcode-select -p`, com aviso para rodar `xcode-select --install`
- `.gitattributes` forcando LF nos `*.sh`; `setup.sh` e `update.sh` versionados como executaveis
  (`100755`), entao `./setup.sh` funciona logo apos o clone

### Corrigido
- **Mac sem Homebrew seguia com erros enganosos** — cada `brew install` falhava com `command not found`
  e o setup acabava em "Node.js nao encontrado". Agora `setup.sh` e `update.sh` param logo no inicio
  com erro dizendo que o Homebrew e obrigatorio (https://brew.sh)
- **Setup abortava no Apple Silicon com o Homebrew fora do `PATH`** — `/opt/homebrew` so entra no
  `PATH` via `brew shellenv`; o `brew install node` falhava com `command not found` e o script saia
  com "Node.js nao encontrado". Agora `setup.sh` e `update.sh` carregam o `brew shellenv` na sessao
  e avisam para persistir no `~/.zprofile`
- **`npm install -g` com `EACCES` num Mac Intel com Homebrew e Node do `.pkg` oficial** — a checagem
  olhava `/usr/local/lib` (do usuario, via Homebrew) e ignorava o `node_modules` do root; agora olha
  `lib/node_modules` quando existe
- **Stubs das Xcode Command Line Tools (CLT) contavam como instalados** — sem as CLT, `/usr/bin/git`
  e `/usr/bin/python3` so abriam o instalador grafico, que aparecia no meio da execucao; agora contam
  como ausentes e sao instalados via `brew`
- `update.sh` sugeria `sudo brew install -y pipx` e `sudo brew install -y tmux` no macOS; agora as
  dicas sao `brew install <pacote>` — o Homebrew nunca roda com `sudo`
- O aviso de Python 3.10+ ausente dizia "Em RHEL 9: sudo ... python3.12" em qualquer plataforma;
  no macOS agora sugere `brew install python`
- A dica de `PATH` para `~/.local/bin` citava o `~/.bashrc`, que o bash de login do macOS nao le;
  no macOS agora aponta para o `~/.zshrc` (shell padrao) ou o `~/.bash_profile`
- `python3.14` faltava na lista de interpretadores candidatos do fallback em venv

---

## [1.3.0] - 2026-08-07

### Adicionado
- **graphify** ([Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify)) — instalado
  automaticamente nos tres scripts via PyPI `graphifyy` + `graphify install`. Transforma qualquer
  pasta num grafo de conhecimento consultavel (`/graphify`, `/graphify query`, `/graphify path`)
- Backup datado do `~/.claude/CLAUDE.md` (`CLAUDE.md.bak.AAAAMMDD-HHMMSS`) antes de sobrescrever,
  em `setup.sh` e `setup.ps1`
- Suporte a Fedora 40+ e RHEL/Rocky/Alma/CentOS Stream 9-10 em `setup.sh` e `update.sh`
- Deteccao automatica de distro via `/etc/os-release` (familias `rhel`, `debian`, `brew`)
- Instalacao de dependencias faltando (git, Node.js, tmux, pipx) com confirmacao do usuario
- Flags `--yes`, `--dry-run` e `--detect-only` em `setup.sh`
- Variavel `UCS_FORCE_FAMILY` para testar outras familias de distro sem trocar de maquina
- Resumo de avisos ao final da execucao

### Corrigido
- **claude-squad nunca era instalado no Fedora/RHEL** — a instalacao do tmux so cobria `brew` e `apt-get`
- **SuperClaude falhava no Fedora/RHEL** — o Python do sistema e `externally-managed` (PEP 668);
  agora a instalacao usa `pipx`, com fallback para venv em `~/.claude/venv-superclaude`
- `set -e` combinado com a ausencia do CLI `claude` abortava o script no passo dos MCPs,
  pulando CLAUDE.md, `ultimate-claude.md` e a Caveman Skill
- `npm install -g` falhava com `EACCES` quando o Node vinha do gerenciador de pacotes
  (prefix `/usr`); o prefix agora e movido para `$HOME/.local` quando nao e gravavel
- `~/.local/bin` e adicionado ao `PATH` da sessao, com instrucao para persistir
- `setup.ps1`: backticks de markdown no here-string `@"..."@` eram interpretados como escape do
  PowerShell (`` `npx repomix` `` inseria uma quebra de linha no `CLAUDE.md` gerado)
- Contador de passos padronizado para `[1/11]`..`[11/11]` nos scripts Linux/Mac e Windows
- **graphify passou a rodar depois do CLAUDE.md** — `graphify install` anexa o proprio bloco de
  trigger ao `~/.claude/CLAUDE.md`, e o passo do CLAUDE.md sobrescrevia o arquivo inteiro logo em
  seguida, apagando o bloco. O template deixou de duplicar o trigger; se o `install` nao anexar
  nada, os scripts escrevem um bloco de fallback
- `setup.ps1`: `pip install graphifyy` tinha o erro engolido por `Out-Null` e a falha era reportada
  como "graphify nao esta no PATH"; agora `$LASTEXITCODE` e checado e as ultimas linhas do pip aparecem

---

## [1.2.0] - 2026-04-23

### Adicionado
- Frontend Design Plugin (oficial Anthropic) — instalado automaticamente nos scripts Windows e Linux/Mac
- Documentacao completa do plugin em `docs/ultimate-claude.md`
- Secao do plugin no README com exemplos de uso e dicas

### Corrigido
- Contador de passos inconsistente nos scripts (`[1/7]` a `[7/8]` corrigido para `[1/9]` a `[9/9]`)
- `setup.sh` agora detecta `pip3` como fallback quando `pip` nao esta disponivel

---

## [1.0.1] - 2026-04-16

### Alterado
- Movidos `ultimate-claude.md` e `INSTALL_LOG.md` para a pasta `docs/`
- README atualizado com secao de documentacao e links para `docs/`
- Scripts de instalacao ajustados para referenciar novo caminho `docs/ultimate-claude.md`

---

## [1.0.0] - 2026-04-16

### Adicionado
- Script de instalacao Windows (`setup.ps1`)
- Script de instalacao Linux/Mac (`setup.sh`)
- GSD v1.36 — workflow spec-driven + 8 hooks + 73 skills
- SuperClaude v4.3 — 31 comandos + 20 agentes
- repomix — empacotador de codebase para IA
- ccusage — dashboard de tokens
- task-master-ai — gerenciamento de tarefas
- claude-squad — multi-agente paralelo (requer tmux/WSL2)
- MCP: sequential-thinking, context7, filesystem
- CLAUDE.md global template
- README completo em PT-BR com guia de uso de agentes
- CREDITS.md com creditos a todos os projetos originais
- Licenca MIT
