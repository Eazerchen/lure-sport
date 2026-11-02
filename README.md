# Lure Sport Tracker (路亚运动追踪 App)

> **专为路亚钓手打造的 Apple Watch 独立作钓与运动复盘工具**
> 原生 iOS + watchOS | SwiftData 本地优先 | 零服务器成本 | App Store 付费买断制

---

## 核心架构概览

本项目严格遵循 **KISS（简洁至上）** 原则与 **Local-First（本地优先）** 架构设计，全流程无需自建服务器，无任何第三方云端月租负债：

```
h:\luresport\
├── Shared\                     // iOS 与 watchOS 双端共享核心模块
│   ├── Models\                 // SwiftData 数据实体
│   │   ├── TackleModels.swift  // 竿(Rod)、轮(Reel)、线(Line)、假饵(Lure)、组合(Combo)
│   │   └── SessionModels.swift // 出钓会话(FishingSession)、打点事件(FishingEvent)
│   ├── Dictionary\             // 装备联想词库
│   │   └── TackleDictionary.swift // 内置 Shimano, Daiwa 等主流热门品牌与型号
│   ├── Engine\                 // 动力学算法引擎
│   │   ├── CastingDetector.swift // CoreMotion 50Hz 四阶段状态机抛竿识别算法
│   │   └── CastingAlgorithmSimulation.swift // 徒步晃动 vs 远投发力时序波形仿真
│   └── Sync\                   // 离线通信
│       └── WatchSessionSyncService.swift // 跨端蓝牙/近场 Wi-Fi 离线传输 DTO
├── LureWatch\                  // Apple Watch 独立端
│   ├── Workouts\               // 运动与传感器后台保活
│   │   └── FishingWorkoutManager.swift // HealthKit Fishing Workout + 50Hz 采样
│   ├── Views\                  // 极简盲操界面
│   │   └── WatchActiveSessionView.swift // 湿手大字高对比主屏 (抛投数/心率/卡路里/一键打标)
│   └── Intents\                // 物理按键适配
│       └── LureAppIntents.swift // Apple Watch Ultra 橙色 Action 按键一键打标
└── LurePhone\                  // iPhone 主端
    └── Views\
        ├── Locker\             // 装备库管理
        │   └── TackleLockerView.swift // 出钓套(Combo)管理、拟饵盒、智能联想录入
        └── Summary\            // 数字化复盘
            └── SessionSummaryCardView.swift // Strava 风格高逼格暗黑战报 (一键渲染高清长图导出)
```

---

## 核心技术点说明

### 1. 抛竿识别引擎 (CastingDetector)
*   **采样频率**：50Hz (每 20ms 一帧)，捕获手腕三轴线性加速度与角速度。
*   **四段状态机**：
    1.  `idle`：正常涉水或收线晃动，加速度平缓。
    2.  `backcast`：后摆蓄力，手腕后仰导致角速度反向突变。
    3.  `forwardSwing`：向前爆发，合成线性加速度冲破 2.2G 阈值，角速度顺向高速旋转。
    4.  `followThrough`：出线减速与制动，触发有效抛投计数 +1，并记录峰值 G-Force。
*   **防抖机制**：内置 1.5 秒 Debounce 窗口，彻底过滤假动作与余震。

### 2. 水上零摩擦交互
*   **大字号极简屏**：大字显示 `CASTS` 累计抛投数，亮色高反差，强光或水雾下清晰可见。
*   **盲操打标**：
    *   单击：标记**咬口 (Bite)**，轻微振动。
    *   大按钮/长按：标记**中鱼 (Catch)**，强庆祝振动。
*   **Apple Watch Ultra Action 物理按键**：出水搏鱼时，无需看屏幕，按下侧边橙色按键即完成中鱼打标。

### 3. 数据与隐私保障
*   数据保存在用户 iPhone 与 Apple Watch 本地沙盒（SwiftData SQLite）。
*   双端在水边无手机网络环境下，通过蓝牙直连通信（`WatchConnectivity`）。
*   用户换机通过苹果官方 `CloudKit` 私有数据库自动还原，钓点与战绩严密保护，开发者服务器成本为 **0 元**。

---

## Xcode 工程接入指南

1. 在 Xcode 中新建一个 **iOS App with Watch App** 项目。
2. 将 `Shared`、`LureWatch`、`LurePhone` 代码拖入对应 Target：
   * `Shared` 勾选 **iOS Target** 与 **Watch Target**。
   * `LureWatch` 仅勾选 **Watch Target**。
   * `LurePhone` 仅勾选 **iOS Target**。
3. **Capabilities 配置**：
   * 在 Watch App 中添加：`HealthKit`、`Workout Processing`（后台运行权限）。
   * 在 iPhone App 中添加：`HealthKit`、`Push Notifications`（可选）、`iCloud` (CloudKit)。
4. **Info.plist 权限声明**：
   * `NSMotionUsageDescription`: "用于在 Apple Watch 上精准识别您的路亚抛投动作。"
   * `NSHealthShareUsageDescription`: "用于在出钓期间记录您的心率、消耗卡路里与涉水运动数据。"
   * `NSHealthUpdateUsageDescription`: "用于将路亚出钓活动保存至 Apple 健身记录。"
   * `NSPhotoLibraryAddUsageDescription`: "用于将生成的路亚出钓长图战报保存至系统相册。"
