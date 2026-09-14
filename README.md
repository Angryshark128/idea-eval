# idea-eval

5 阶段开发 / 开源项目创意评估框架，做成可移植的 agent skill。

> 不是决策引擎，是评审专家。砍掉明显不行的，让你在更少的选项里做权衡。

## 5 个阶段

1. **红线**（一票否决）— 法律风险 / 道德底线 / 合规资质 / 技术不可控
2. **定位** — 技术影响力 / 可商业化变现 / 纯粹想做点能被人用的东西
3. **价值** — 真实问题 / 现有方案够好 / 人群够大（附死海陷阱）
4. **难度 × 成本** — 难度可不可控 + 7 类成本（基础设施 / API / 一次性 / 维护 / 分发 / 冷启动 / 运营）
5. **框架退场** — ROI / 时间窗口 / 机会成本 → 自己定

任意阶段不通过即停。全部通过后框架让位，个人权衡接手。

## 支持平台

skill 格式基于通用 Markdown + YAML frontmatter，跨 agent 可移植：

| 平台 | 默认安装路径 |
|------|-------------|
| Claude Code（Anthropic） | `~/.claude/skills/idea-eval/` |
| Codex（OpenAI CLI） | `~/.codex/skills/idea-eval/` |
| Kimi Code（Moonshot） | `~/.kimi-code/skills/idea-eval/` |

不限于上表 — 任何按相同规范加载 SKILL.md 的 agent 都能用。任何自定义路径也支持（见下文 IDEA_EVAL_DIR）。

## 安装

### 一键（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/Angryshark128/idea-eval/main/install.sh | bash
```

脚本会：

1. 探测机器上已存在的 agent skills 目录
2. 列出选项让你挑要装到哪些（默认交互，TTY 下会让你输编号）
3. 逐 target 装：先 `git pull` 升级，失败再备份重装

只检测到一个 agent 时跳过选择直接装；无可用 TTY 时默认全装。

示例（检测到 2 个 agent 时）：

```
[i] 检测到 2 个 agent skills 目录：
  1) /root/.claude/skills                   (Claude Code)
  2) /root/.codex/skills                    (Codex)
  a) 全部安装

选择要安装的目标 [a 或编号如 1,3，留空=全部]: _
```

### 一键全装（跳过交互）

```bash
curl -fsSL .../install.sh | bash -s -- --all
# 或
curl -fsSL .../install.sh | bash -s -- -y
```

### 高级用法

```bash
# 指定 ref（tag / 分支）
IDEA_EVAL_REF=v0.3 curl -fsSL .../install.sh | bash

# 装到自定义路径（跳过探测与交互）
IDEA_EVAL_DIR=/path/to/skills/idea-eval curl -fsSL .../install.sh | bash

# 显式列出多个目标（覆盖探测与交互，冒号分隔）
IDEA_EVAL_TARGETS="$HOME/.claude/skills/idea-eval:$HOME/.codex/skills/idea-eval" \
    curl -fsSL .../install.sh | bash
```

### 手动

```bash
git clone https://github.com/Angryshark128/idea-eval.git ~/.claude/skills/idea-eval
# 其他平台同理
git clone https://github.com/Angryshark128/idea-eval.git ~/.codex/skills/idea-eval
git clone https://github.com/Angryshark128/idea-eval.git ~/.kimi-code/skills/idea-eval
```

### 升级

```bash
cd <skill 目录>  # 任一已装的目录
git pull
```

### 卸载

```bash
rm -rf ~/.claude/skills/idea-eval ~/.codex/skills/idea-eval ~/.kimi-code/skills/idea-eval
```

## 使用

直接对装了 skill 的 agent 说：

- "帮我用 idea-eval 评估这个点子：[描述]"
- "这个 idea 值得做吗？"
- "我有几个候选 idea，帮我过滤一下"

skill 会按 5 阶段产出结构化报告，含每阶段证据、来源链接、核实日期与最终建议（通过 / 待修订 / 否决）。

## 文件结构

```
idea-eval/
├── SKILL.md                  # 主入口：5 阶段流程 + 输出模板
├── README.md                 # 本文件
├── LICENSE                   # MIT
├── CHANGELOG.md              # 变更日志
├── install.sh                # 一键安装脚本（多平台，交互式选目标）
└── references/
    ├── framework.md          # 每阶段的详细判据 + 推荐核实源
    ├── output-template.md    # 报告结构（含来源列）
    ├── examples.md           # 三个走完流程的例子（含来源）
    └── checklist.md          # 快速扫描单（含时效核对）
```

## 框架来源

提炼自[《我自己在用的一套开发创意评估框架》](https://blog.hancic.site/post/e2150d68-7f24-457d-949b-79485df559d3)。

## License

MIT