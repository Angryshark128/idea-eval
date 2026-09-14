# Changelog

## v0.5 — 2026-09-15

### 变更

- **install.sh 改为交互式选目标**：探测到多 agent 时不再自动全装，列出编号让用户挑
  - 仅 1 个 agent 时跳过询问直接装
  - 有 TTY 时通过 `/dev/tty` 读输入，curl | bash 也能交互
  - 无 TTY 且未指定 `--all` 时默认全装并 warn 提示
- 新增 CLI 标志：`--all` / `-y` 跳过交互装全部
- 新增环境变量 `IDEA_EVAL_NONINTERACTIVE=1`（CI / 脚本场景）
- README.md 同步：删掉"Kimi Code"专属感，平台表改为"支持平台"列示，新增交互示例与 `--all` 用法

### 兼容

- `IDEA_EVAL_DIR` / `IDEA_EVAL_TARGETS` 行为不变
- 已装用户升级后下次 `curl | bash` 重装会进入交互流程

## v0.4 — 2026-09-15

### 变更

- **多平台化**：skill 不再绑定 Kimi Code。一键安装脚本自动探测 Claude Code / Codex / Kimi Code 的 skills 目录并装到所有存在的路径。
  - 默认目标：`~/.claude/skills/idea-eval/`、`~/.codex/skills/idea-eval/`、`~/.kimi-code/skills/idea-eval/`
  - `IDEA_EVAL_DIR` 仍可指定单一路径；新增 `IDEA_EVAL_TARGETS`（冒号分隔）显式列出多目标
  - 安装脚本改为单次克隆、按目标复制分发
- **中文化 verdict 词**：`PROCEED` → `通过`、`NEEDS REWORK` → `待修订`、`REJECT` → `否决`
- **SKILL.md 加支持平台段落**（frontmatter 仍保持中性）
- README.md 改写：列出多平台路径、安装 / 升级 / 卸载命令

### 兼容

- SKILL.md frontmatter 格式不变，agent 描述字段不绑定具体平台
- `IDEA_EVAL_DIR` 单目标行为与之前一致
- 已装用户：执行 `git pull` 升级即可，自动获得多平台脚本

## v0.3 — 2026-09-15

### 变更

- 中文化评审标准：所有 SKILL.md / references/* 改中文
- 加「强制前提：信息核实」章节，禁止凭印象下结论
- 每条结论后必须带来源 + 核实日期（YYYY-MM-DD）
- 各阶段「先查这些」段落，挂具体法规 / 评测 / 定价源
- output-template.md / checklist.md 加「时效声明」与下次复核时间

## v0.2 — 2026-09-15

### 变更

- 加一键安装脚本 `install.sh`：既有安装走 `git pull` 升级，失败再备份重装
- 接受 `IDEA_EVAL_REF`（ref / tag）、`IDEA_EVAL_DIR`（路径）环境变量

## v0.1 — 2026-09-15

### 初始发布

- 5 阶段开发 / 开源项目创意评估框架
- SKILL.md + references/{framework, output-template, examples, checklist}.md
- MIT License
- 提炼自[《我自己在用的一套开发创意评估框架》](https://blog.hancic.site/post/e2150d68-7f24-457d-949b-79485df559d3)