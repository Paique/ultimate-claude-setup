#!/bin/bash
# Ultimate Claude Code Setup - Linux/Mac
# Executa como: chmod +x setup.sh && ./setup.sh
# Compativel com o bash 3.2 nativo do macOS: nada de bash 4+ (declare -A, ${var,,}, mapfile).
#
# Flags:
#   -y, --yes       Instala dependencias faltando sem perguntar
#       --dry-run   Mostra o que seria executado, sem executar nada
#       --detect-only  Só imprime a plataforma detectada e sai

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ASSUME_YES="${UCS_ASSUME_YES:-0}"
DRY_RUN=0
DETECT_ONLY=0
WARNINGS=()

for arg in "$@"; do
    case "$arg" in
        -y|--yes)      ASSUME_YES=1 ;;
        --dry-run)     DRY_RUN=1 ;;
        --detect-only) DETECT_ONLY=1 ;;
        -h|--help)
            echo "Uso: ./setup.sh [-y|--yes] [--dry-run] [--detect-only]"
            exit 0 ;;
        *)
            echo -e "${RED}Argumento desconhecido: $arg${NC}"; exit 1 ;;
    esac
done

warn() {
    echo -e "${YELLOW}  $1${NC}"
    WARNINGS+=("$1")
}

# Executa um comando, ou apenas imprime se --dry-run.
run() {
    if [ "$DRY_RUN" = "1" ]; then
        echo -e "${CYAN}  [dry-run] $*${NC}"
        return 0
    fi
    "$@"
}

# ---------------------------------------------------------------------------
# Deteccao de plataforma
# ---------------------------------------------------------------------------
detect_platform() {
    OS_NAME="desconhecido"; OS_ID=""; OS_VERSION=""
    PKG_FAMILY="unknown"; PKG_MGR=""
    # Vira 0 no macOS sem Xcode Command Line Tools (ver macos_preflight).
    MACOS_CLT=1

    if [ "$(uname -s)" = "Darwin" ]; then
        OS_NAME="macOS"; OS_ID="macos"; OS_VERSION="$(sw_vers -productVersion 2>/dev/null)"
        PKG_FAMILY="brew"; PKG_MGR="brew"
    elif [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_ID="$ID"
        OS_NAME="${PRETTY_NAME:-$ID}"
        OS_VERSION="${VERSION_ID:-}"
        case " $ID ${ID_LIKE:-} " in
            *" fedora "*|*" rhel "*|*" centos "*)
                PKG_FAMILY="rhel" ;;
            *" debian "*|*" ubuntu "*)
                PKG_FAMILY="debian" ;;
        esac
    fi

    # Override para testar outras familias sem trocar de maquina.
    if [ -n "${UCS_FORCE_FAMILY:-}" ]; then
        PKG_FAMILY="$UCS_FORCE_FAMILY"
        PKG_MGR=""
    fi

    case "$PKG_FAMILY" in
        rhel)
            if   command -v dnf5    >/dev/null 2>&1; then PKG_MGR="dnf5"
            elif command -v dnf     >/dev/null 2>&1; then PKG_MGR="dnf"
            elif command -v yum     >/dev/null 2>&1; then PKG_MGR="yum"
            else PKG_MGR="dnf"; fi ;;
        debian) PKG_MGR="apt-get" ;;
        brew)   PKG_MGR="brew" ;;
    esac
}

# Nome do pacote da familia atual. Uso: pkg_name <rhel> <debian> <brew>
pkg_name() {
    case "$PKG_FAMILY" in
        rhel)   echo "$1" ;;
        debian) echo "$2" ;;
        brew)   echo "$3" ;;
        *)      echo "$1" ;;
    esac
}

# Comando de instalacao completo para os pacotes recebidos.
pkg_install_cmd() {
    case "$PKG_FAMILY" in
        rhel)   echo "sudo $PKG_MGR install -y $*" ;;
        debian) echo "sudo apt-get install -y $*" ;;
        brew)   echo "brew install $*" ;;
        *)      echo "" ;;
    esac
}

# Sem as Xcode Command Line Tools, /usr/bin/git e /usr/bin/python3 do macOS sao stubs:
# estao no PATH, mas so abrem o instalador grafico das CLT em vez de rodar.
is_macos_shim() {
    [ "$MACOS_CLT" = "0" ] && [ "$(command -v "$1")" = "/usr/bin/$1" ]
}

# ensure_pkg <binario> <pkg-rhel> <pkg-debian> <pkg-brew>
# Retorna 0 se o binario esta disponivel ao final, 1 caso contrario.
ensure_pkg() {
    local bin="$1"; shift
    local pkg; pkg="$(pkg_name "$@")"

    command -v "$bin" >/dev/null 2>&1 && ! is_macos_shim "$bin" && return 0

    if [ "$PKG_FAMILY" = "unknown" ]; then
        warn "'$bin' nao encontrado e a distro nao foi reconhecida. Instale manualmente."
        return 1
    fi

    local cmd; cmd="$(pkg_install_cmd "$pkg")"

    if [ "$PKG_FAMILY" != "brew" ] && ! command -v sudo >/dev/null 2>&1; then
        warn "'$bin' nao encontrado e 'sudo' nao existe. Instale como root: $cmd"
        return 1
    fi

    echo -e "${YELLOW}  '$bin' nao encontrado. Comando de instalacao:${NC}"
    echo -e "${CYAN}    $cmd${NC}"

    if [ "$ASSUME_YES" != "1" ] && [ "$DRY_RUN" != "1" ]; then
        local answer
        read -r -p "  Executar agora? [s/N] " answer
        case "$answer" in
            s|S|y|Y) ;;
            *) warn "Instalacao de '$bin' recusada. Rode manualmente: $cmd"; return 1 ;;
        esac
    fi

    # shellcheck disable=SC2086
    if ! run $cmd; then
        warn "Falha ao instalar '$bin'. Rode manualmente: $cmd"
        return 1
    fi

    [ "$DRY_RUN" = "1" ] && return 0

    if ! command -v "$bin" >/dev/null 2>&1; then
        if [ "$PKG_FAMILY" = "rhel" ] && [ "$OS_ID" != "fedora" ]; then
            warn "'$bin' continua ausente. Em RHEL/Rocky/Alma o pacote pode vir do EPEL: sudo $PKG_MGR install -y epel-release"
        else
            warn "'$bin' continua ausente apos a instalacao."
        fi
        return 1
    fi
    return 0
}

# No Apple Silicon o Homebrew fica em /opt/homebrew, que so entra no PATH depois do
# 'brew shellenv' no ~/.zprofile. Se o binario existir fora do PATH, carrega nesta sessao.
load_brew_env() {
    command -v brew >/dev/null 2>&1 && return 0
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$brew_bin" ] || continue
        eval "$("$brew_bin" shellenv)"
        warn "Homebrew fora do PATH. Adicione ao ~/.zprofile: eval \"\$($brew_bin shellenv)\""
        return 0
    done
    return 1
}

# macOS: o Homebrew e obrigatorio (e o gerenciador da familia 'brew'); sem ele o setup para
# antes de instalar qualquer coisa. Tambem checa as Xcode Command Line Tools.
macos_preflight() {
    if ! load_brew_env; then
        echo -e "${RED}ERRO: Homebrew nao encontrado. No macOS o setup depende dele.${NC}"
        echo -e "${RED}  Instale em https://brew.sh e rode ./setup.sh de novo.${NC}"
        exit 1
    fi

    [ "$OS_ID" = "macos" ] || return 0
    local clt_dir
    clt_dir="$(xcode-select -p 2>/dev/null)" && [ -d "$clt_dir" ] && return 0
    MACOS_CLT=0
    warn "Xcode Command Line Tools ausentes: git e python3 do sistema nao funcionam sem elas. Rode: xcode-select --install"
}

# Garante que ~/.local/bin esta no PATH desta sessao.
ensure_local_bin_path() {
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) return 0 ;;
    esac
    export PATH="$HOME/.local/bin:$PATH"
    # No macOS o shell padrao e o zsh, e o bash de login le ~/.bash_profile, nao o ~/.bashrc.
    if [ "$OS_ID" = "macos" ]; then
        warn "Adicione ao seu ~/.zshrc (ou ~/.bash_profile, se usa bash): export PATH=\"\$HOME/.local/bin:\$PATH\""
        return 0
    fi
    warn "Adicione ao seu ~/.bashrc ou ~/.zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
}

# Escolhe um python3 >= 3.10. Ecoa o binario ou string vazia.
find_python() {
    local candidate
    for candidate in python3 python3.14 python3.13 python3.12 python3.11 python3.10; do
        is_macos_shim "$candidate" && continue
        if command -v "$candidate" >/dev/null 2>&1 &&
           "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)' 2>/dev/null; then
            echo "$candidate"; return 0
        fi
    done
    echo ""
}

# Resolve pipx uma unica vez (0 = indisponivel, 1 = disponivel, -1 = ainda nao checado).
PIPX_READY=-1
ensure_pipx() {
    [ "$PIPX_READY" = "1" ] && return 0
    [ "$PIPX_READY" = "0" ] && return 1
    if ensure_pkg pipx pipx pipx pipx; then PIPX_READY=1; return 0; fi
    PIPX_READY=0; return 1
}

# Instala um pacote Python de CLI. Fedora/RHEL/Debian marcam o python do sistema
# como externally-managed (PEP 668), entao 'pip install' falha — pipx e o caminho
# suportado, com venv dedicado como fallback.
# Uso: py_cli_install <pacote-pypi> <binario>
py_cli_install() {
    local pkg="$1" bin="$2"
    local venv="$HOME/.claude/venv-$bin"

    if ensure_pipx; then
        if run pipx install "$pkg" || run pipx upgrade "$pkg"; then
            return 0
        fi
        warn "pipx falhou para '$pkg' — tentando venv dedicado"
    fi

    local py; py="$(find_python)"
    if [ -z "$py" ]; then
        if [ "$PKG_FAMILY" = "brew" ]; then
            warn "Nenhum python3 >= 3.10 encontrado. Instale: brew install python"
            return 1
        fi
        warn "Nenhum python3 >= 3.10 encontrado. Em RHEL 9: sudo $PKG_MGR install -y python3.12"
        return 1
    fi

    warn "Instalando '$pkg' em venv dedicado: $venv"
    run mkdir -p "$HOME/.claude" "$HOME/.local/bin" || return 1
    [ -x "$venv/bin/pip" ] || run "$py" -m venv "$venv" || return 1
    run "$venv/bin/pip" install --upgrade "$pkg" || return 1
    run ln -sf "$venv/bin/$bin" "$HOME/.local/bin/$bin"
    return 0
}

detect_platform

echo -e "${CYAN}=== ULTIMATE CLAUDE CODE SETUP ===${NC}"
echo -e "${NC}Versao: 1.3 | Data: 2026-08-07${NC}"
echo -e "${NC}Plataforma: ${OS_NAME} (familia: ${PKG_FAMILY}, gerenciador: ${PKG_MGR:-nenhum})${NC}"
[ "$DRY_RUN" = "1" ] && echo -e "${YELLOW}MODO DRY-RUN — nada sera modificado${NC}"
echo ""

if [ "$DETECT_ONLY" = "1" ]; then
    echo "OS_ID=$OS_ID"
    echo "OS_VERSION=$OS_VERSION"
    echo "PKG_FAMILY=$PKG_FAMILY"
    echo "PKG_MGR=$PKG_MGR"
    exit 0
fi

if [ "$PKG_FAMILY" = "unknown" ]; then
    warn "Distro nao reconhecida — dependencias faltando serao apenas reportadas."
fi

# Pre-requisitos
echo -e "${YELLOW}[1/11] Verificando pre-requisitos...${NC}"

# Antes do ensure_local_bin_path: o 'brew shellenv' reordena o PATH (path_helper).
if [ "$PKG_FAMILY" = "brew" ]; then
    macos_preflight
fi
ensure_local_bin_path

ensure_pkg git git git git || true

if ! ensure_pkg node nodejs nodejs node; then
    echo -e "${RED}ERRO: Node.js nao encontrado. Instale: https://nodejs.org${NC}"; exit 1
fi
if ! ensure_pkg npm npm npm node; then
    command -v npm >/dev/null 2>&1 || { echo -e "${RED}ERRO: npm nao encontrado.${NC}"; exit 1; }
fi
echo -e "  Node: $(node --version)"
echo -e "  npm:  $(npm --version)"

# Node do dnf/apt (prefix /usr) ou do .pkg oficial do macOS (prefix /usr/local) faz
# 'npm install -g' falhar com EACCES. Checa lib/node_modules quando existe: num Mac Intel
# com Homebrew, /usr/local/lib e do usuario, mas o node_modules do .pkg continua do root.
NPM_PREFIX="$(npm config get prefix 2>/dev/null || echo "")"
NPM_GLOBAL_DIR="$NPM_PREFIX/lib/node_modules"
[ -d "$NPM_GLOBAL_DIR" ] || NPM_GLOBAL_DIR="$NPM_PREFIX/lib"
if [ -n "$NPM_PREFIX" ] && [ ! -w "$NPM_GLOBAL_DIR" ] 2>/dev/null; then
    warn "npm prefix '$NPM_PREFIX' nao e gravavel. Trocando para \$HOME/.local"
    run npm config set prefix "$HOME/.local"
    ensure_local_bin_path
fi

# GSD
echo ""
echo -e "${YELLOW}[2/11] Instalando GSD (Get Shit Done)...${NC}"
if run npx get-shit-done-cc@latest --claude --global; then
    echo -e "${GREEN}  GSD instalado!${NC}"
else
    warn "GSD falhou. Rode manualmente: npx get-shit-done-cc@latest --claude --global"
fi

# NPM Tools
echo ""
echo -e "${YELLOW}[3/11] Instalando ferramentas npm globais...${NC}"
for tool in repomix ccusage task-master-ai; do
    if run npm install -g "$tool"; then
        echo -e "${GREEN}  $tool OK${NC}"
    else
        warn "$tool falhou. Rode manualmente: npm install -g $tool"
    fi
done

# SuperClaude
echo ""
echo -e "${YELLOW}[4/11] Instalando SuperClaude...${NC}"
if py_cli_install superclaude superclaude; then
    if run env PYTHONIOENCODING=utf-8 superclaude install; then
        echo -e "${GREEN}  SuperClaude OK (31 comandos + 20 agentes)${NC}"
    else
        warn "'superclaude install' falhou. Rode: PYTHONIOENCODING=utf-8 superclaude install"
    fi
else
    warn "PULADO — instale manualmente: pipx install superclaude && superclaude install"
fi

# MCP Servers
echo ""
echo -e "${YELLOW}[5/11] Configurando MCP Servers...${NC}"
if command -v claude >/dev/null 2>&1 || [ "$DRY_RUN" = "1" ]; then
    run claude mcp add sequential-thinking -- npx -y "@modelcontextprotocol/server-sequential-thinking" \
        && echo -e "${GREEN}  sequential-thinking OK${NC}" || warn "sequential-thinking falhou"

    run claude mcp add context7 -- npx -y "@upstash/context7-mcp" \
        && echo -e "${GREEN}  context7 OK${NC}" || warn "context7 falhou"

    run claude mcp add filesystem -- npx -y "@modelcontextprotocol/server-filesystem" "$HOME" \
        && echo -e "${GREEN}  filesystem OK${NC}" || warn "filesystem falhou"
else
    warn "CLI 'claude' nao encontrado. Instale o Claude Code e rode:"
    echo -e "${CYAN}    claude mcp add sequential-thinking -- npx -y \"@modelcontextprotocol/server-sequential-thinking\"${NC}"
    echo -e "${CYAN}    claude mcp add context7 -- npx -y \"@upstash/context7-mcp\"${NC}"
    echo -e "${CYAN}    claude mcp add filesystem -- npx -y \"@modelcontextprotocol/server-filesystem\" \"\$HOME\"${NC}"
fi

# CLAUDE.md
echo ""
echo -e "${YELLOW}[6/11] Criando CLAUDE.md global...${NC}"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

# O arquivo e sobrescrito por completo — se ja existir, faz backup datado antes.
if [ -f "$CLAUDE_MD" ]; then
    CLAUDE_MD_BAK="$CLAUDE_MD.bak.$(date +%Y%m%d-%H%M%S)"
    if [ "$DRY_RUN" = "1" ]; then
        echo -e "${CYAN}  [dry-run] cp $CLAUDE_MD $CLAUDE_MD_BAK${NC}"
    else
        cp "$CLAUDE_MD" "$CLAUDE_MD_BAK"
    fi
    echo -e "${YELLOW}  CLAUDE.md ja existia — backup em $CLAUDE_MD_BAK${NC}"
    warn "Seu CLAUDE.md anterior foi sobrescrito. Backup: $CLAUDE_MD_BAK — reaplique suas regras customizadas."
fi

if [ "$DRY_RUN" = "1" ]; then
    echo -e "${CYAN}  [dry-run] escreveria $CLAUDE_MD${NC}"
else
    mkdir -p "$HOME/.claude"
    cat > "$CLAUDE_MD" << 'EOF'
# Instrucoes Globais do Claude

## Identidade
Voce e um assistente de desenvolvimento senior. Responda em portugues (pt-BR).

## Comportamento
- Seja conciso. Sem resumos ao final.
- Leia antes de editar.
- Nao adicione funcionalidades nao solicitadas.

## Economia de Tokens
- Use repomix: `npx repomix`
- Adicione `use context7` para docs atualizadas.
- Use `/gsd-quick` para tarefas simples.

## Ferramentas
- GSD: /gsd-new-project, /gsd-plan-phase, /gsd-execute-phase, /gsd-quick
- SuperClaude: /sc:implement, /sc:research, @backend-architect, etc.
- repomix, ccusage, task-master
- MCPs: sequential-thinking, context7, filesystem
EOF
fi
echo -e "${GREEN}  CLAUDE.md criado${NC}"

# graphify — o pacote PyPI se chama 'graphifyy'; o CLI e a skill sao 'graphify'.
# Roda DEPOIS do CLAUDE.md: 'graphify install' anexa o proprio bloco de trigger ao arquivo,
# e o passo anterior sobrescreve o CLAUDE.md por completo.
echo ""
echo -e "${YELLOW}[7/11] Instalando graphify...${NC}"
if py_cli_install graphifyy graphify; then
    if run graphify install; then
        echo -e "${GREEN}  graphify OK — use: /graphify${NC}"
        # Se o 'install' nao anexou o trigger (formato mudou), escreve um fallback.
        if [ "$DRY_RUN" != "1" ] && ! grep -qi "graphify" "$CLAUDE_MD" 2>/dev/null; then
            cat >> "$CLAUDE_MD" << 'EOF'

## graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill before doing anything else.
EOF
            echo -e "${GREEN}  trigger do graphify anexado ao CLAUDE.md${NC}"
        fi
    else
        warn "'graphify install' falhou. Rode manualmente: graphify install"
    fi
else
    warn "PULADO — instale manualmente: pipx install graphifyy && graphify install"
fi

# Claude Squad (requer tmux)
echo ""
echo -e "${YELLOW}[8/11] Instalando claude-squad...${NC}"
if ensure_pkg tmux tmux tmux tmux; then
    if run bash -c 'curl -fsSL https://raw.githubusercontent.com/smtg-ai/claude-squad/main/install.sh | bash'; then
        echo -e "${GREEN}  claude-squad OK — use: cs${NC}"
        if [ "$DRY_RUN" != "1" ] && ! command -v cs >/dev/null 2>&1; then
            warn "'cs' nao esta no PATH — verifique \$HOME/.local/bin"
        fi
    else
        warn "claude-squad falhou. Rode manualmente o install.sh do repositorio."
    fi
else
    warn "PULADO — tmux indisponivel, claude-squad nao instalado"
fi

# Copiar ultimate-claude.md
echo ""
echo -e "${YELLOW}[9/11] Copiando ultimate-claude.md...${NC}"
if [ -f "$SCRIPT_DIR/docs/ultimate-claude.md" ]; then
    run cp "$SCRIPT_DIR/docs/ultimate-claude.md" "$HOME/ultimate-claude.md"
    echo -e "${GREEN}  Copiado para $HOME/ultimate-claude.md${NC}"
else
    warn "docs/ultimate-claude.md nao encontrado"
fi

# Frontend Design Plugin
echo ""
echo -e "${YELLOW}[10/11] Instalando plugin frontend-design...${NC}"
if command -v claude >/dev/null 2>&1 || [ "$DRY_RUN" = "1" ]; then
    run claude plugins install frontend-design 2>/dev/null \
        && echo -e "${GREEN}  frontend-design OK (UI distintiva, sem AI slop)${NC}" \
        || warn "frontend-design: reinicie o Claude Code e execute 'claude plugins install frontend-design'"
else
    warn "CLI 'claude' ausente — rode depois: claude plugins install frontend-design"
fi

# Caveman Skill
echo ""
echo -e "${YELLOW}[11/11] Instalando Caveman Skill...${NC}"
if [ -f "$SCRIPT_DIR/skills/caveman.md" ]; then
    run mkdir -p "$HOME/.claude/skills"
    run cp "$SCRIPT_DIR/skills/caveman.md" "$HOME/.claude/skills/caveman.md"
    echo -e "${GREEN}  Caveman Skill instalado em ~/.claude/skills/caveman.md${NC}"
    echo -e "${YELLOW}  Ative em: https://claude.ai/customize/skills (cole o conteudo do arquivo)${NC}"
else
    warn "skills/caveman.md nao encontrado"
fi

echo ""
echo -e "${CYAN}=================================${NC}"
echo -e "${GREEN}SETUP COMPLETO!${NC}"
echo -e "${CYAN}=================================${NC}"
echo ""
echo -e "  GSD           -> /gsd-new-project"
echo -e "  SuperClaude   -> /sc:implement, @backend-architect"
echo -e "  graphify      -> /graphify (grafo de conhecimento da codebase)"
echo -e "  repomix       -> npx repomix"
echo -e "  MCPs          -> sequential-thinking, context7, filesystem"
echo -e "  claude-squad  -> cs  (requer tmux)"
echo -e "  frontend-design -> plugin ativo (UI distintiva)"
echo -e "  caveman skill -> /caveman (economiza ~75% tokens)"

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}AVISOS (${#WARNINGS[@]}):${NC}"
    for w in "${WARNINGS[@]}"; do
        echo -e "${YELLOW}  - $w${NC}"
    done
fi

echo ""
echo -e "${CYAN}LEIA: ~/ultimate-claude.md${NC}"
echo -e "${YELLOW}REINICIE o Claude Code para ativar tudo!${NC}"
