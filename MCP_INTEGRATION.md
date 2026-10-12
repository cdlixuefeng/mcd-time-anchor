# MCP_INTEGRATION.md —— 麦当劳 MCP 能力对接说明

本文档说明「麦味时光锚点」实际使用的麦当劳 MCP Server、Tool、调用流程与业务价值。

## 一、接入信息

| 项目 | 值 |
|---|---|
| MCP Server | 麦当劳中国官方 MCP Server |
| 接入地址 | `https://mcp.mcd.cn` |
| 传输协议 | Streamable HTTP |
| 鉴权方式 | `Authorization: Bearer <MCP_TOKEN>`（Token 通过环境变量注入，仓库内仅占位符） |
| 限流 | 600 次/分钟（Skill 内所有调用均为单次会话内少量串行调用，远低于限流阈值） |

## 二、使用的 Tool 清单

| Tool | 用途 | 在本项目中的角色 | 必用 |
|---|---|---|---|
| `now-time-info` | 获取当前时间 | 时光锚点打点、早餐/宵夜等餐段判断 | ✅ |
| `query-nearby-stores` | 按城市+关键词搜门店 | 门店路由：「春熙路」→ 门店列表（searchType=2） | ✅ |
| `query-meals` | 查询门店菜单 | 拉取可售餐品、现价/原价/促销标签、商品编码 | ✅ |
| `query-store-coupons` | 查询指定门店可用券 | 门店维度券核对，参与最优价计算 | ✅ |
| `available-coupons` | 麦麦省可领券列表 | 提示用户「还有可领的券」 | ✅ |
| `query-my-coupons` | 账号卡包券资产 | 用户已有券总览 | ✅ |
| `calculate-price` | 商品价格计算 | 带券实算应付总价，输出省钱金额 | ✅ |
| `create-order` | 创建订单 | 生成正式订单与官方支付链接 | ✅ |
| `query-order` | 订单详情 | 支付前确认订单内容 | ✅ |
| `order-list` | 历史订单 | 时光锚点初始化、老样子冷启动参考 | ✅ |
| `auto-bind-coupons` | 一键领券 | 用户授权后批量领取麦麦省券 | 可选 |
| `query-my-account` | 积分账户 | 积分临期提醒（增值功能） | 可选 |
| `campaign-calendar` | 活动日历 | 营销活动播报（增值功能） | 可选 |

**本项目未使用**：外送地址类、团餐/助餐类、商城积分兑换类、抽奖类、主题活动预约类工具（保留后续版本扩展空间）。

### 实测状态（2026-10-12 全量实测通过）

| 状态 | 工具 |
|---|---|
| ✅ 已实测调通（只读） | `now-time-info`、`query-nearby-stores`、`query-meals`、`query-store-coupons`、`available-coupons`、`query-my-account`、`query-my-coupons`、`calculate-price`、`order-list`、`query-order` |
| ✅ 已实测调通（写操作） | `create-order`（测试单已取消）、`cancel-order`、`auto-bind-coupons`（7 张全成功） |
| 🔧 设计已就绪、未实测 | `campaign-calendar`（增值功能，规划中） |

### 实测发现的接口细节（已同步 SKILL.md）

1. **订单状态枚举以 `orderStatus` 文本为准**：文档称待支付=1，实际返回 `orderStatus:"待支付"` + `status:"10"`。对账逻辑改用文本判断，数字码仅参考。
2. **单位差异**：`calculate-price` 金额单位为分；`create-order` / `query-order` 为元。
3. **支付链接有效期**：`create-order` 返回 `expirePayTime`，实测约 15 分钟，超时需重新下单。
4. **`calculate-price` 返回 `takeWayList`**（堂食/外带），`create-order` 到店场景必传 `takeWayCode`。
5. **`create-order` 不代付**：返回 `payH5Url` 官方支付链接，支付在麦当劳侧完成。

## 三、核心调用流程

### 流程 A：老样子极速单

```text
1. now-time-info                       → 当前时间/餐段
2. 读取本地记忆 memory/profile.json     → 常用门店 storeCode、固定餐品、个性化备注
3. query-nearby-stores(searchType=2)   → 校验常用门店仍在可用范围（用户指定新地点时换店）
4. query-meals(storeCode, orderType=1) → 确认固定餐品在售及现价
5. query-store-coupons(storeCode)      → 门店可用券
6. calculate-price(...)                → 多组合比价，输出最省方案
7. create-order(...)                   → 生成订单 + 官方支付链接；同时写 pending 锚点（status=pending，不计入任何统计）
8. query-order                         → 对账：核实真实支付后锚点转 confirmed（取消/未付转 cancelled，档案不留）
9. 推演取材                             → 仅 confirmed 锚点进入时光复盘与平行宇宙推演
```

### 流程 B：自然语言点餐（首次/换口味）

```text
1. now-time-info                       → 餐段判断
2. query-nearby-stores(city, keyword)  → 用户说「春熙路」直接关键词搜索，无需经纬度
3. 用户确认门店                          → 拿到 storeCode
4. query-meals                         → 按意图（辣/清淡/实惠/热量）推荐餐品
5. 流程 A 第 5~9 步
```

### 流程 C：冷启动建档

```text
1. 无本地记忆时，order-list 拉近期订单作参考（读不到则全新引导）
2. 对话式引导：常去哪家店、常点什么、有什么忌口备注
3. 用户确认后写入 memory/profile.json，宣布「老样子已就位」
```

## 四、关键枚举字段（实测口径）

| 字段 | 枚举 |
|---|---|
| 订单类型 orderType | 1 到店（含自取/得来速） / 2 外送（含麦乐送/团餐） |
| 就餐方式 beType | 1 到店自取 / 2 麦乐送 / 5 得来速 / 6 团餐 |
| 门店搜索 searchType | 1 收藏门店 / 2 城市+关键词位置搜索 |
| 商品优惠 discountType | null / 促销优惠 / 麦金卡优惠 / 随单购麦金卡优惠 等 |

## 五、能力边界与补全策略

| MCP 原生边界 | 本项目的处理 |
|---|---|
| 无法获取用户实时位置 | 基础版用城市/商圈关键词走 `searchType=2` 搜索，实测「成都+春熙路」秒级返回门店列表，无需任何地图 API；增强版可选接入高德/百度地理编码，缺 key 自动回退基础版 |
| `create-order` 不代付 | 明确告知用户支付在官方收银台完成，订单生成后给出官方支付链接与有效时长 |
| 历史订单仅近期范围 | 长期画像不依赖 MCP，由 Skill 本地记忆（`memory/profile.json`）从首单起自主积累 |
| 券规则不承诺可用性 | `query-my-coupons` 仅作资产展示；下单必以 `query-store-coupons` + `calculate-price` 的门店实算结果为准 |

## 六、业务价值

1. **把 30+ 个点餐决策压缩成一句话**：搜店、选餐、比券、凑单、备注，全链路由 Skill 编排，用户只说「老样子」。
2. **实算省钱，不做口头优惠**：所有「省了多少」均来自 `calculate-price` 的真实应付金额对比，可复现、可验证。
3. **补齐 MCP 的长期记忆短板**：MCP 是无状态接口，Skill 用本地记忆为其加上「越用越懂你」的时间维度——这是本项目的差异化所在。
