# TAOUP 工程规则（可执行版）

一句话总纲：优先构建“简单、透明、可组合”的系统，用稳定接口连接小而清晰的部件，让正确性、维护性与协作效率长期占优。

## 17 条核心规则（The 17 Rules）

1. **Rule of Modularity**：把系统拆成小模块；每个模块只做一件事，并通过清晰接口协作。
2. **Rule of Clarity**：代码和接口优先可读可懂；拒绝炫技式 cleverness。
3. **Rule of Composition**：默认支持组合（pipe、API、脚本编排）；不要封死上下游。
4. **Rule of Separation**：分离 policy 与 mechanism，分离 interface 与 engine。
5. **Rule of Simplicity**：先做最简单可行方案；复杂度必须有可证明收益。
6. **Rule of Parsimony**：不到必要不做“大而全”；先用小程序协同解决问题。
7. **Rule of Transparency**：让内部状态和决策路径可观察、可检查、可追踪。
8. **Rule of Robustness**：鲁棒性来自简单+透明；异常路径要可预期。
9. **Rule of Representation**：把知识放进数据结构/配置，不要硬编码在分支逻辑里。
10. **Rule of Least Surprise**：接口行为符合直觉与惯例，默认值要可预测。
11. **Rule of Silence**：默认输出只给必要信息；机器可消费信息走结构化通道。
12. **Rule of Repair**：能修复则修复；不能修复就尽早、响亮、可定位地失败。
13. **Rule of Economy**：优先节省 programmer time，再优化 machine time。
14. **Rule of Generation**：优先自动生成重复代码/配置；减少手工复制粘贴。
15. **Rule of Optimization**：先实现正确版本并测量，再做有证据的优化。
16. **Rule of Diversity**：避免“一招鲜吃遍天”；按场景选择合适方案。
17. **Rule of Extensibility**：为未来变化预留扩展点，但避免提前实现不存在的需求。

## 实战检查清单

### 设计（Design）

- 是否有清晰模块边界与单一职责？
- 是否把 policy/mechanism、interface/engine 分离？
- 是否优先选择文本化、可演化的数据与协议表示？
- 是否定义了失败语义、重试语义、幂等语义？

### 实现（Implementation）

- 关键路径是否保持简单、可测试、可替换？
- 是否消除重复逻辑（SPOT），用生成或抽象替代复制？
- 日志/错误是否包含定位问题所需的最小充分上下文？
- 是否先保证正确，再做性能微调？

### 接口（Interfaces）

- CLI/API 默认行为是否符合 Least Surprise？
- 输出是否稳定、可脚本化、可机器解析（避免噪声）？
- 是否支持组合调用（stdin/stdout、管道、子命令、批量模式）？
- 交互式能力是否可由非交互接口覆盖？

### 配置（Configuration）

- 仅暴露必要配置项，默认值是否安全且合理？
- 配置优先级是否明确（CLI > env > file）？
- 配置变更是否具备兼容策略与迁移提示？
- 是否避免把业务策略硬编码在实现中？

### 调试（Debugging）

- 是否提供分级日志（quiet/info/debug/trace）？
- 是否可复现问题（固定输入、固定版本、固定环境）？
- 错误是否 fail fast，且信息可直接指导修复？
- 是否有最小诊断命令或健康检查入口？

### 优化（Optimization）

- 是否有基线指标与 profiling 证据？
- 优化目标是 latency 还是 throughput，是否明确？
- 是否优先低风险手段（批处理、缓存、并行重叠）？
- 优化后是否保持可读性、可维护性和正确性？

### 文档（Documentation）

- README/CLI help/示例是否与当前行为一致？
- 是否记录关键设计约束、边界条件和非目标？
- 是否提供故障排查路径（常见错误->处理步骤）？
- 变更是否附带迁移说明与兼容性说明？

### 协作（Collaboration）

- 变更是否“小步提交、清晰信息、可审查”？
- 是否复用现有工具与社区约定，避免重复造轮子？
- License/依赖来源/安全影响是否透明？
- 是否让他人可在本地快速复现与验证？

## 决策顺序（规则冲突时）

1. **Correctness & Repair first**：先保证正确性、可恢复性、可诊断性。
2. **Clarity before cleverness**：若性能技巧损害可读性，默认回退到清晰实现。
3. **Simplicity over feature creep**：需求不确定时，选更小、更可演进方案。
4. **Composition over monolith**：能通过组合解决，就不做耦合的大一统实现。
5. **Economy with evidence**：优化和抽象都要有数据或维护收益证明。
6. **Extensibility with restraint**：只预留明确扩展点，不提前实现未来功能。

## 非目标（避免过度设计）

- 不是追求“最通用框架”或“一次性解决所有场景”。
- 不是为了模式而模式、为了抽象而抽象。
- 不是把可配置性无限扩张到难以理解和测试。
- 不是在无测量证据下做性能工程。
- 不是以牺牲可维护性换取短期炫技实现。
