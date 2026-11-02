import Foundation

// MARK: - 佩戴与配置

/// 手表佩戴与持竿手关系
public enum WristOrientation: String, Codable, CaseIterable {
    case castingHand = "佩戴在持竿手 (推荐，识别最精准)"
    case reelHand = "佩戴在摇轮手"
}

/// 抛竿状态机阶段
public enum CastingState {
    case idle           // 静息 / 慢速收线中
    case backcast       // 后摆蓄力 (角速度反向)
    case forwardSwing   // 强力前挥 (高G爆发)
    case followThrough  // 随动减速与出线
}

/// 抛竿检测配置参数
public struct CastingSensitivityConfig {
    public var minForwardGForce: Double   // 前挥爆发触发门限 (G)
    public var minAngularSpeed: Double    // 前挥旋转角速度门限 (rad/s)
    public var debounceIntervalSec: Double// 抛投防抖最小间隔 (秒)

    public static let standard = CastingSensitivityConfig(
        minForwardGForce: 2.2,       // 2.2 倍重力加速度
        minAngularSpeed: 3.5,        // 3.5 rad/s 旋转角速度
        debounceIntervalSec: 1.5     // 1.5 秒内不重复计次
    )

    public static let sensitive = CastingSensitivityConfig(
        minForwardGForce: 1.6,       // 适合微物轻竿微动作抛投
        minAngularSpeed: 2.5,
        debounceIntervalSec: 1.2
    )
}

// MARK: - 抛投事件回调数据

public struct CastDetectionResult {
    public let timestamp: Date
    public let peakGForce: Double         // 爆发峰值 G 值 (例如 3.8G)
    public let durationMs: Int            // 挥竿发力历时 (毫秒)
}

// MARK: - 核心算法检测器 (CastingDetector)

public final class CastingDetector {
    
    // 配置
    public var orientation: WristOrientation
    public var config: CastingSensitivityConfig
    
    // 状态机
    private var currentState: CastingState = .idle
    private var stateEnterTime: Date = Date()
    private var lastValidCastTime: Date = Date.distantPast
    
    // 当前挥竿周期内的统计
    private var currentSwingPeakG: Double = 0.0

    // 外部回调
    public var onCastDetected: ((CastDetectionResult) -> Void)?

    public init(
        orientation: WristOrientation = .castingHand,
        config: CastingSensitivityConfig = .standard
    ) {
        self.orientation = orientation
        self.config = config
    }

    /// 核心采样输入接口 (以 50Hz 频率调用)
    /// - Parameters:
    ///   - userAccelX: 用户线性加速度 X (不含重力，单位 G)
    ///   - userAccelY: 用户线性加速度 Y
    ///   - userAccelZ: 用户线性加速度 Z
    ///   - rotX: 俯仰角速度 (Pitch rate, rad/s)
    ///   - rotY: 偏航角速度 (Roll rate, rad/s)
    ///   - rotZ: 偏航角速度 (Yaw rate, rad/s)
    ///   - timestamp: 当前采样时间
    public func processSample(
        userAccelX: Double,
        userAccelY: Double,
        userAccelZ: Double,
        rotX: Double,
        rotY: Double,
        rotZ: Double,
        timestamp: Date = Date()
    ) {
        // 1. 计算总合成线性加速度 (矢量模长)
        let totalLinearG = sqrt(userAccelX * userAccelX + userAccelY * userAccelY + userAccelZ * userAccelZ)
        
        // 2. 计算合成旋转角速度
        let totalAngularSpeed = sqrt(rotX * rotX + rotY * rotY + rotZ * rotZ)

        // 3. 防抖检测：如果距离上一次确认抛投不足防抖窗口，直接忽略
        let timeSinceLastCast = timestamp.timeIntervalSince(lastValidCastTime)
        if timeSinceLastCast < config.debounceIntervalSec {
            currentState = .idle
            return
        }

        let timeInState = timestamp.timeIntervalSince(stateEnterTime)

        // 4. 状态机流转
        switch currentState {
        case .idle:
            // 检测是否有后摆蓄力动作 (向后拉伸手腕，角速度开始爬升)
            if totalAngularSpeed > 1.8 && totalLinearG < 1.2 {
                transit(to: .backcast, at: timestamp)
            } else if totalLinearG > config.minForwardGForce && totalAngularSpeed > config.minAngularSpeed {
                // 如果没有明显的后摆 (如快甩/荡抛)，直接爆发前冲
                transit(to: .forwardSwing, at: timestamp)
                currentSwingPeakG = totalLinearG
            }

        case .backcast:
            // 在后摆状态中，最长等待 0.8 秒必须转入前挥，超时则视为普通日常甩手
            if timeInState > 0.8 {
                transit(to: .idle, at: timestamp)
                break
            }

            // 捕捉前挥爆发瞬间
            if totalLinearG > config.minForwardGForce && totalAngularSpeed > config.minAngularSpeed {
                transit(to: .forwardSwing, at: timestamp)
                currentSwingPeakG = totalLinearG
            }

        case .forwardSwing:
            // 更新该次挥竿过程中的最高峰值 G 值
            if totalLinearG > currentSwingPeakG {
                currentSwingPeakG = totalLinearG
            }

            // 当加速度快速回落 (出线、刹车或随动减速阶段)
            if totalLinearG < (config.minForwardGForce * 0.6) || timeInState > 0.6 {
                // 前挥有效时间通常在 100ms ~ 500ms 之间
                if timeInState >= 0.08 && timeInState <= 0.6 {
                    transit(to: .followThrough, at: timestamp)
                } else {
                    transit(to: .idle, at: timestamp)
                }
            }

        case .followThrough:
            // 确认一次有效抛投！
            let castDurationMs = Int(timeInState * 1000)
            let result = CastDetectionResult(
                timestamp: timestamp,
                peakGForce: currentSwingPeakG,
                durationMs: castDurationMs
            )
            
            lastValidCastTime = timestamp
            onCastDetected?(result)
            
            // 重置回归静息态
            transit(to: .idle, at: timestamp)
        }
    }

    private func transit(to newState: CastingState, at time: Date) {
        self.currentState = newState
        self.stateEnterTime = time
        if newState == .idle {
            currentSwingPeakG = 0.0
        }
    }
    
    /// 重置状态机
    public func reset() {
        currentState = .idle
        currentSwingPeakG = 0.0
        lastValidCastTime = Date.distantPast
    }
}
