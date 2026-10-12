# workbuddy.md — WorkBuddy 开发上下文

本项目使用腾讯 WorkBuddy 作为唯一开发环境完成：需求构思、MCP 实测、代码与文档编写、可视化器开发、演示物料制作、仓库与报名提交，全部在 WorkBuddy 会话中由 AI 智能体（老辈子）与开发者（shadow）协作完成。

## 一、开发环境

- 开发工具：WorkBuddy（AI 智能体平台，本次大赛官方合作伙伴）
- MCP 接入：WorkBuddy 自定义连接器配置麦当劳 MCP（`https://mcp.mcd.cn`，Streamable HTTP + Bearer Token），会话内直接调用全部工具
- 仓库管理：WorkBuddy 内通过 gh CLI / GitHub API 创建仓库、提交代码、发布报名 Issue

## 二、需求演进（WorkBuddy 会话中的真实迭代轨迹）

| 轮次 | 时间 | 关键决策 |
|---|---|---|
| v0.1 | 2026-10-09 | 初始方案：极速单（老样子）+ 时光锚点记忆；WorkBuddy 会话内实测发现 `query-nearby-stores` 支持 city+keyword 搜索，砍掉地图 API 依赖 |
| v0.2 | 2026-10-12 | 对照原始需求全面审查：补「平行宇宙推演」流程 + 能力分级（可选高德/百度 key，缺省自动降级） |
| v0.3 | 2026-10-12 | 第一性原理审查：锚点改 pending+对账制（只认真实支付）；移除品牌对比表述（合规）；极简确认模式 |
| 发布 | 2026-10-12 | 时光档案可视化器 + 演示 GIF；全链路写操作实测；提交报名 Issue #546 |

## 三、MCP 实测记录（WorkBuddy 会话内直接调用麦当劳 MCP 完成）

只读：`now-time-info` / `query-my-account` / `query-nearby-stores`（成都+春熙路，返回 5 店） / `query-meals`（storeCode 3450410 全菜单） / `query-store-coupons` / `available-coupons` / `query-my-coupons`（6 张） / `calculate-price`（板烧三件套 ¥34.50） / `order-list` / `query-order`

写操作：`create-order`（测试订单创建成功，返回官方支付链接）→ `query-order`（状态核对一致）→ `cancel-order`（测试单已取消，不留脏单）；`auto-bind-coupons`（7 张全部领取成功）

实测修正文档偏差 3 处：订单状态以 `orderStatus` 文本为准（文档枚举与实际不符）；`calculate-price` 单位为分而订单接口为元；支付链接实测有效期约 15 分钟。

## 四、开发过程中的关键决策

1. **零外部依赖优先**：基础版不依赖地图/天气 API，`searchType=2` 关键词搜店即可完整运行；增强 key 可选、静默降级
2. **档案真实性红线**：锚点 pending → query-order 对账 → confirmed 三态流转，未支付订单永不入档
3. **工程工具自建**：因本机网络限制，自研 `scripts/api-commit.sh`（GitHub Git Data API 提交脚本）完成全部推送
4. **物料自产**：时光档案可视化器、自动播放演示页、GIF 均由 WorkBuddy 会话内产出并实测渲染

## 五、成果

- 仓库：https://github.com/cdlixuefeng/mcd-time-anchor
- 报名 Issue：https://github.com/M-China/mcd-developer-innovation-challenge/issues/546
- SKILL.md v0.3：6 大流程（极速单/自然语言点餐/建档/时光复盘/平行宇宙/优惠查询）+ 对账流程 + 5 条红线
- 附件资产：单文件可视化器（file:// 双击即用）、12 秒流程演示 GIF、示例数据集
