import Foundation
import SwiftData

// MARK: - 基础枚举与数据结构

/// 作钓事件类型
public enum FishingEventType: String, Codable, CaseIterable {
    case bite = "就饵咬口 (Bite)"
    case catchFish = "成功中鱼 (Catch)"
    case unhooked = "跑鱼 / 脱钩"
    case lureChanged = "更换拟饵"
}

/// 轨迹经纬度与高程数据点 (Codable 存储在会话中)
public struct RoutePoint: Codable, Hashable {
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var timestamp: Date

    public init(latitude: Double, longitude: Double, altitude: Double = 0.0, timestamp: Date = Date()) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
}

// MARK: - SwiftData 实体

/// 作钓过程中的单次打点事件 (如: 咬口、中鱼)
@Model
public final class FishingEvent {
    public var id: UUID
    public var eventType: FishingEventType
    public var timestamp: Date
    public var latitude: Double
    public var longitude: Double
    
    // 环境基线 (在手表端或手机端打点时捕获)
    public var pressureHpa: Double?        // 瞬时微气压 (百帕)
    public var temperatureC: Double?       // 温度
    
    // 中鱼专项信息 (可选补录)
    public var fishSpecies: String?        // 鱼种 (如: 大口黑鲈、翘嘴、鳜鱼、马口)
    public var lengthCm: Double?           // 长度 (cm)
    public var weightKg: Double?           // 重量 (kg)
    public var photoIdentifier: String?    // 本地相册或沙盒图片标识
    public var usedLureName: String?       // 当时使用的假饵名称
    public var notes: String?              // 钓手备注心得

    // 关联的会话
    public var session: FishingSession?

    public init(
        id: UUID = UUID(),
        eventType: FishingEventType,
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        pressureHpa: Double? = nil,
        temperatureC: Double? = nil,
        fishSpecies: String? = nil,
        lengthCm: Double? = nil,
        weightKg: Double? = nil,
        photoIdentifier: String? = nil,
        usedLureName: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.pressureHpa = pressureHpa
        self.temperatureC = temperatureC
        self.fishSpecies = fishSpecies
        self.lengthCm = lengthCm
        self.weightKg = weightKg
        self.photoIdentifier = photoIdentifier
        self.usedLureName = usedLureName
        self.notes = notes
    }
}

/// 完整出钓会话实体
@Model
public final class FishingSession {
    public var id: UUID
    public var title: String               // 会话标题 (如: "千岛湖早口路亚")
    public var startTime: Date
    public var endTime: Date?
    
    // 运动与穿戴健康数据 (HealthKit / CoreMotion 聚合)
    public var totalCastsCount: Int        // 累计抛投挥竿数
    public var maxCastGForce: Double       // 最高单次挥竿爆发力度 (G-Force)
    public var activeCaloriesKcal: Double  // 活动卡路里消耗 (kcal)
    public var averageHeartRateBpm: Double // 平均心率 (bpm)
    public var maxHeartRateBpm: Double     // 最高心率 (bpm)
    public var walkingSteps: Int           // 涉水 / 岸边徒步步数
    public var walkingDistanceMeters: Double // 移动总距离 (米)

    // 轨迹路线 (JSON 编码的经纬度点序列)
    public var encodedRoutePoints: Data?
    
    // 关联的装备组合
    public var combo: TackleCombo?

    // 包含的所有事件 (一对多关联)
    @Relationship(deleteRule: .cascade, inverse: \FishingEvent.session)
    public var events: [FishingEvent]

    public init(
        id: UUID = UUID(),
        title: String = "日常路亚出钓",
        startTime: Date = Date(),
        endTime: Date? = nil,
        totalCastsCount: Int = 0,
        maxCastGForce: Double = 0.0,
        activeCaloriesKcal: Double = 0.0,
        averageHeartRateBpm: Double = 0.0,
        maxHeartRateBpm: Double = 0.0,
        walkingSteps: Int = 0,
        walkingDistanceMeters: Double = 0.0,
        combo: TackleCombo? = nil,
        events: [FishingEvent] = []
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.totalCastsCount = totalCastsCount
        self.maxCastGForce = maxCastGForce
        self.activeCaloriesKcal = activeCaloriesKcal
        self.averageHeartRateBpm = averageHeartRateBpm
        self.maxHeartRateBpm = maxHeartRateBpm
        self.walkingSteps = walkingSteps
        self.walkingDistanceMeters = walkingDistanceMeters
        self.combo = combo
        self.events = events
    }

    /// 会话持续时长 (秒)
    public var durationSeconds: TimeInterval {
        let end = endTime ?? Date()
        return max(0, end.timeIntervalSince(startTime))
    }

    /// 中鱼总数计算
    public var totalCatches: Int {
        events.filter { $0.eventType == .catchFish }.count
    }

    /// 咬口总数计算
    public var totalBites: Int {
        events.filter { $0.eventType == .bite }.count
    }

    /// 编码轨迹辅助
    public func setRoutePoints(_ points: [RoutePoint]) {
        self.encodedRoutePoints = try? JSONEncoder().encode(points)
    }

    /// 解码轨迹辅助
    public func getRoutePoints() -> [RoutePoint] {
        guard let data = encodedRoutePoints,
              let points = try? JSONDecoder().decode([RoutePoint].self, from: data) else {
            return []
        }
        return points
    }
}
