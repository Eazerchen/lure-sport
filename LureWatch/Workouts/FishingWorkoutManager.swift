import Foundation
import HealthKit
import CoreMotion
import WatchKit

/// Apple Watch 作钓后台会话管理器 (结合 HealthKit 与 CoreMotion)
@MainActor
public final class FishingWorkoutManager: NSObject, ObservableObject {
    
    public static let shared = FishingWorkoutManager()

    // 状态发布
    @Published public var isActive: Bool = false
    @Published public var totalCastsCount: Int = 0
    @Published public var currentHeartRate: Double = 0.0
    @Published public var activeCalories: Double = 0.0
    @Published public var sessionDuration: TimeInterval = 0.0
    @Published public var recentCatchesCount: Int = 0
    @Published public var recentBitesCount: Int = 0
    @Published public var maxCastGForce: Double = 0.0

    // 系统服务
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private let motionManager = CMMotionManager()
    
    // 算法检测器
    private let castingDetector = CastingDetector(orientation: .castingHand, config: .standard)

    // 定时器
    private var durationTimer: Timer?
    private var sessionStartDate: Date?

    override private init() {
        super.init()
        setupCastingCallback()
    }

    private func setupCastingCallback() {
        castingDetector.onCastDetected = { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.totalCastsCount += 1
                if result.peakGForce > self.maxCastGForce {
                    self.maxCastGForce = result.peakGForce
                }
                // 抛竿时给一个极其微弱轻快的触觉反馈 (确认已计次)
                WKInterfaceDevice.current().play(.directionUp)
            }
        }
    }

    /// 启动作钓 Workout
    public func startSession() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)

        let config = HKWorkoutConfiguration()
        config.activityType = .fishing
        config.locationType = .outdoor

        workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        workoutBuilder = workoutSession?.associatedWorkoutBuilder()

        workoutSession?.delegate = self
        workoutBuilder?.delegate = self
        workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

        let startDate = Date()
        self.sessionStartDate = startDate
        workoutSession?.startActivity(with: startDate)
        workoutBuilder?.beginCollection(withStart: startDate) { _, _ in }

        // 启动 50Hz 传感器监听
        startMotionSampling()

        // 启动前台 UI 秒表计时
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.sessionStartDate else { return }
            self.sessionDuration = Date().timeIntervalSince(start)
        }

        self.isActive = true
        WKInterfaceDevice.current().play(.start)
    }

    /// 启动 CoreMotion 50Hz 采样
    private func startMotionSampling() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.02 // 50Hz (每 20ms 一次)
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            self.castingDetector.processSample(
                userAccelX: motion.userAcceleration.x,
                userAccelY: motion.userAcceleration.y,
                userAccelZ: motion.userAcceleration.z,
                rotX: motion.rotationRate.x,
                rotY: motion.rotationRate.y,
                rotZ: motion.rotationRate.z,
                timestamp: Date()
            )
        }
    }

    /// 结束作钓
    public func stopSession() async {
        durationTimer?.invalidate()
        durationTimer = nil
        motionManager.stopDeviceMotionUpdates()

        workoutSession?.end()
        let endDate = Date()
        workoutBuilder?.endCollection(withEnd: endDate) { [weak self] _, _ in
            self?.workoutBuilder?.finishWorkout { _, _ in }
        }

        self.isActive = false
        WKInterfaceDevice.current().play(.stop)
    }

    /// 一键标记咬口 (Bite)
    public func markBite() {
        recentBitesCount += 1
        WKInterfaceDevice.current().play(.click)
    }

    /// 一键标记中鱼 (Catch)
    public func markCatch() {
        recentCatchesCount += 1
        WKInterfaceDevice.current().play(.success) // 强震动庆祝
    }
}

// MARK: - HealthKit 代理回调

extension FishingWorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    public func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // 状态同步
    }

    public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}

    public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)

            Task { @MainActor in
                if quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                    if let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                        self.currentHeartRate = value
                    }
                } else if quantityType.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue {
                    let energyUnit = HKUnit.kilocalorie()
                    if let value = statistics?.sumQuantity()?.doubleValue(for: energyUnit) {
                        self.activeCalories = value
                    }
                }
            }
        }
    }
}
