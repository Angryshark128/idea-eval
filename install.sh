#!/usr/bin/env bash
# idea-eval 一键安装脚本（多平台，交互式选择目标）
#
# 自动探测机器上已安装的 agent，列出选项让用户挑要装到哪些。
#
# 默认安装路径：
#   ~/.claude/skills/idea-eval/   Claude Code
#   ~/.codex/skills/idea-eval/    Codex
#   ~/.kimi-code/skills/idea-eval/ Kimi Code
#
# 用法：
#   curl -fsSL https://raw.githubusercontent.com/Angryshark128/idea-eval/main/install.sh | bash
#
# 自动全装所有探测到的目标（跳过交互）：
#   curl -fsSL .../install.sh | bash -s -- --all
#
# 指定 ref / tag：
#   IDEA_EVAL_REF=v0.3 curl -fsSL .../install.sh | bash
#
# 指定单路径（跳过探测和交互）：
#   IDEA_EVAL_DIR=/path/to/skills/idea-eval curl -fsSL .../install.sh | bash
#
# 显式列出多个目标（覆盖探测和交互，冒号分隔）：
#   IDEA_EVAL_TARGETS="$HOME/.claude/skills/idea-eval:$HOME/.codex/skills/idea-eval" curl -fsSL .../install.sh | bash
#
# 升级：
#   cd <skill 目录> && git pull
#
# 卸载：
#   rm -rf <skill 目录>
set -euo pipefail

REPO_URL="${IDEA_EVAL_REPO:-https://github.com/Angryshark128/idea-eval.git}"
REF="${IDEA_EVAL_REF:-main}"

# 颜色
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    C_INFO=$'\033[1;34m'; C_OK=$'\033[1;32m'; C_WARN=$'\033[1;33m'; C_ERR=$'\033[1;31m'; C_RST=$'\033[0m'
else
    C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_RST=""
fi
info() { printf '%s[i]%s %s\n' "${C_INFO}" "${C_RST}" "$*"; }
ok()   { printf '%s[+]%s %s\n' "${C_OK}"   "${C_RST}" "$*"; }
warn() { printf '%s[!]%s %s\n' "${C_WARN}" "${C_RST}" "$*"; }
err()  { printf '%s[x]%s %s\n' "${C_ERR}"  "${C_RST}" "$*" >&2; }

# 默认平台列表（按主流度排）
PLATFORM_DEFAULTS=(
    "${HOME}/.claude/skills/idea-eval"
    "${HOME}/.codex/skills/idea-eval"
    "${HOME}/.kimi-code/skills/idea-eval"
)

# 平台名推测（按父路径里出现的目录段匹配，兼容 IDEA_EVAL_TARGETS 给的绝对路径）
guess_platform() {
    local parent="$1"
    case "${parent}" in
        */.claude*)    echo "Claude Code" ;;
        */.codex*)     echo "Codex" ;;
        */.kimi-code*) echo "Kimi Code" ;;
        *)             echo "Custom" ;;
    esac
}

# 解析 CLI 参数
ALL_FLAG=0
for arg in "$@"; do
    case "$arg" in
        --all|-y) ALL_FLAG=1 ;;
        --help|-h)
            sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) err "未知参数：$arg（试试 --help）"; exit 1 ;;
    esac
done

# TTY 检测（在子 shell 中实测打开 /dev/tty，避开 exec fd 重定向的 stderr 噪声）
HAS_TTY=0
if [ -e /dev/tty ] && ( exec 3</dev/tty ) 2>/dev/null; then
    HAS_TTY=1
fi

# 决定目标列表
TARGETS=()
if [ -n "${IDEA_EVAL_TARGETS:-}" ]; then
    IFS=':' read -r -a TARGETS <<< "${IDEA_EVAL_TARGETS}"
elif [ -n "${IDEA_EVAL_DIR:-}" ]; then
    TARGETS=("${IDEA_EVAL_DIR}")
else
    # 探测已存在的 agent skills 目录
    DETECTED=()
    for t in "${PLATFORM_DEFAULTS[@]}"; do
        parent="${t%/skills/idea-eval}"
        if [ -d "${parent}" ]; then
            DETECTED+=("${t}")
        fi
    done

    if [ "${#DETECTED[@]}" -eq 0 ]; then
        err "未检测到任何 agent skills 目录。"
        err "已检查：${HOME}/.claude/skills/, ${HOME}/.codex/skills/, ${HOME}/.kimi-code/skills/"
        err "请先安装 Claude Code / Codex / Kimi Code，或用 IDEA_EVAL_DIR 指定自定义路径。"
        exit 1
    fi

    if [ "${#DETECTED[@]}" -eq 1 ]; then
        # 只有一个目标，直接装
        TARGETS=("${DETECTED[@]}")
        info "检测到 1 个 agent：$(guess_platform "${DETECTED[0]%/skills/idea-eval}") → ${DETECTED[0]}"
    elif [ "${ALL_FLAG}" -eq 1 ] || [ -n "${IDEA_EVAL_NONINTERACTIVE:-}" ]; then
        # 显式全装
        TARGETS=("${DETECTED[@]}")
    elif [ "${HAS_TTY}" -eq 0 ]; then
        # 无 TTY（curl | bash 在某些环境）且未指定 --all：装全部并提示
        echo ""
        info "检测到 ${#DETECTED[@]} 个 agent skills 目录："
        for i in "${!DETECTED[@]}"; do
            parent="${DETECTED[$i]%/skills/idea-eval}"
            platform=$(guess_platform "${parent}")
            printf '  %d) %-40s %s\n' "$((i+1))" "${parent}" "(${platform})"
        done
        warn "无可用 TTY 且未指定 --all，自动安装全部 ${#DETECTED[@]} 个目标"
        warn "如需在非交互场景精确选目标，请用 IDEA_EVAL_TARGETS"
        TARGETS=("${DETECTED[@]}")
    else
        # 交互选
        echo ""
        info "检测到 ${#DETECTED[@]} 个 agent skills 目录："
        for i in "${!DETECTED[@]}"; do
            parent="${DETECTED[$i]%/skills/idea-eval}"
            platform=$(guess_platform "${parent}")
            printf '  %d) %-40s %s\n' "$((i+1))" "${parent}" "(${platform})"
        done
        echo "  a) 全部安装"
        echo ""

        choice=""
        if ! read -rp "选择要安装的目标 [a 或编号如 1,3，留空=全部]: " choice < /dev/tty; then
            warn "从 /dev/tty 读输入失败，自动安装全部 ${#DETECTED[@]} 个目标"
            TARGETS=("${DETECTED[@]}")
        else
            case "${choice}" in
                ""|a|A)
                    TARGETS=("${DETECTED[@]}")
                    ;;
                *)
                    selected=()
                    IFS=',' read -ra parts <<< "${choice}"
                    for p in "${parts[@]}"; do
                        if [[ "${p}" =~ ^[0-9]+$ ]] && [ "${p}" -ge 1 ] && [ "${p}" -le "${#DETECTED[@]}" ]; then
                            selected+=("${DETECTED[$((p-1))]}")
                        else
                            err "无效选择：${p}"
                            exit 1
                        fi
                    done
                    if [ "${#selected[@]}" -eq 0 ]; then
                        err "未选择任何目标"
                        exit 1
                    fi
                    TARGETS=("${selected[@]}")
                    ;;
            esac
        fi
    fi
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
    err "目标列表为空"
    exit 1
fi

# 前置检查
if ! command -v git >/dev/null 2>&1; then
    err "缺少依赖：git。请先安装 git。"
    exit 1
fi

# 临时目录用于克隆
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

info "克隆仓库：${REPO_URL}（ref: ${REF}）"
if ! git clone --depth 1 --branch "${REF}" "${REPO_URL}" "${TMP_DIR}/repo" 2>/dev/null; then
    info "浅克隆指定 ref 失败，尝试不带 --branch"
    if ! git clone --depth 1 "${REPO_URL}" "${TMP_DIR}/repo"; then
        err "克隆失败，请检查网络与仓库地址"
        exit 1
    fi
    if [ "${REF}" != "main" ]; then
        ( cd "${TMP_DIR}/repo" && git checkout "${REF}" ) || {
            err "指定的 ref ${REF} 不存在"
            exit 1
        }
    fi
fi

if [ ! -f "${TMP_DIR}/repo/SKILL.md" ]; then
    err "克隆成功但缺少 SKILL.md —— 仓库可能已损坏"
    exit 1
fi

ok "已克隆 $(git -C "${TMP_DIR}/repo" log -1 --format='%h %s')"

# 逐 target 安装
SUCCESS=()
FAILED=()

for target in "${TARGETS[@]}"; do
    parent="${target%/skills/idea-eval}"
    platform_label=$(guess_platform "${parent}")

    echo ""
    info "──── 目标：${platform_label} → ${target} ────"

    if [ ! -d "${parent}" ]; then
        warn "父目录 ${parent} 不存在，跳过"
        FAILED+=("${target} (父目录不存在)")
        continue
    fi

    mkdir -p "${parent}"

    # 既有安装：优先原地升级
    if [ -d "${target}/.git" ]; then
        info "已有安装，尝试 git pull 升级"
        if git -C "${target}" pull --ff-only 2>/dev/null; then
            ok "已升级（${platform_label}）"
            SUCCESS+=("${target}")
            continue
        fi
        warn "git pull 失败，备份后重装"
        BACKUP="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        mv "${target}" "${BACKUP}"
    elif [ -d "${target}" ]; then
        warn "目录已存在但不是 git 仓库，备份后重装"
        BACKUP="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        mv "${target}" "${BACKUP}"
    fi

    cp -R "${TMP_DIR}/repo" "${target}"

    if [ ! -f "${target}/SKILL.md" ]; then
        err "拷贝后缺少 SKILL.md（${platform_label}）"
        FAILED+=("${target} (拷贝失败)")
        continue
    fi

    ok "已安装（${platform_label}）"
    SUCCESS+=("${target}")
done

echo ""
echo "════════════════════════════════════════"
if [ "${#SUCCESS[@]}" -gt 0 ]; then
    ok "成功 ${#SUCCESS[@]}/${#TARGETS[@]}："
    for s in "${SUCCESS[@]}"; do
        printf '    - %s\n' "${s}"
    done
fi
if [ "${#FAILED[@]}" -gt 0 ]; then
    warn "失败 ${#FAILED[@]}："
    for f in "${FAILED[@]}"; do
        printf '    - %s\n' "${f}"
    done
fi
echo "════════════════════════════════════════"

if [ "${#SUCCESS[@]}" -eq 0 ]; then
    err "所有目标都失败了"
    exit 1
fi

echo ""
info "重启 agent 让 skill 生效"
info "升级：cd <skill 目录> && git pull"
info "反馈：https://github.com/Angryshark128/idea-eval/issues"