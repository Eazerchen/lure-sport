import Foundation
import SwiftData

// MARK: - 装备分类枚举

/// 钓竿调性 (Rod Action / Power)
public enum RodAction: String, Codable, CaseIterable {
    case ul = "UL (极软)"
    case l = "L (软)"
    case ml = "ML (中软)"
    case m = "M (中等)"
    case mh = "MH (中硬)"
    case h = "H (硬)"
    case xh = "XH (极硬)"
}

/// 渔轮类型
public enum ReelType: String, Codable, CaseIterable {
    case baitcaster = "水滴轮 (Baitcaster)"
    case spinning = "纺车轮 (Spinning)"
    case spincast = "封闭轮"
}

/// 钓线材质
public enum LineType: String, Codable, CaseIterable {
    case pe = "PE 编织线"
    case fluorocarbon = "碳素线"
    case nylon = "尼龙线"
    case ester = "酯线"
}

/// 拟饵大类
public enum LureCategory: String, Codable, CaseIterable {
    case minnow = "米诺 (Minnow)"
    case crank = "摇滚 (Crankbait)"
    case popper = "波扒 (Popper)"
    case pencil = "铅笔 (Pencil)"
    case vib = "VIB"
    case softBait = "软饵钓组 (Soft Lure)"
    case spoon = "亮片 / 铁板 (Spoon / Jig)"
    case spinner = "复合亮片 (Spinnerbait)"
    case other = "其他 / 手工饵"
}

/// 沉水属性
public enum BuoyancyType: String, Codable, CaseIterable {
    case floating = "浮水 (F)"
    case suspend = "悬停 (SP)"
    case sinking = "沉水 (S)"
    case fastSinking = "快沉 (FS)"
}

// MARK: - SwiftData 实体模型

/// 钓竿实体
@Model
public final class Rod {
    public var id: UUID
    public var brand: String             // 品牌 (如: Shimano)
    public var modelName: String         // 型号 (如: Poison Adrena)
    public var lengthFeet: Double        // 长度 (英尺，如 6.6)
    public var action: RodAction         // 调性
    public var minLureWeightG: Double    // 最低适投克重 (g)
    public var maxLureWeightG: Double    // 最高适投克重 (g)
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        brand: String,
        modelName: String,
        lengthFeet: Double = 6.6,
        action: RodAction = .m,
        minLureWeightG: Double = 5.0,
        maxLureWeightG: Double = 21.0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.brand = brand
        self.modelName = modelName
        self.lengthFeet = lengthFeet
        self.action = action
        self.minLureWeightG = minLureWeightG
        self.maxLureWeightG = maxLureWeightG
        self.createdAt = createdAt
    }
    
    public var displayName: String {
        "\(brand) \(modelName) (\(action.rawValue))"
    }
}

/// 渔轮实体
@Model
public final class Reel {
    public var id: UUID
    public var brand: String             // 品牌 (如: Daiwa)
    public var modelName: String         // 型号 (如: Tatula SV TW)
    public var type: ReelType            // 类型 (水滴轮/纺车轮)
    public var gearRatio: Double         // 齿轮速比 (如 7.1)
    public var handleSide: String        // 左右手摇臂 (左手 / 右手)
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        brand: String,
        modelName: String,
        type: ReelType = .baitcaster,
        gearRatio: Double = 7.1,
        handleSide: String = "左手",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.brand = brand
        self.modelName = modelName
        self.type = type
        self.gearRatio = gearRatio
        self.handleSide = handleSide
        self.createdAt = createdAt
    }

    public var displayName: String {
        "\(brand) \(modelName) \(gearRatio):1 (\(handleSide))"
    }
}

/// 钓线配置
@Model
public final class FishingLine {
    public var id: UUID
    public var brand: String
    public var type: LineType            // 材质
    public var lineRatingNumber: Double  // 线号 (如 1.0#)
    public var poundTest: Double         // 磅数 (如 16lb)
    public var leaderDescription: String // 前导线说明 (如: 3号碳线 1.5米)
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        brand: String = "常规",
        type: LineType = .pe,
        lineRatingNumber: Double = 1.0,
        poundTest: Double = 16.0,
        leaderDescription: String = "碳素前导 12lb 1.5m",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.brand = brand
        self.type = type
        self.lineRatingNumber = lineRatingNumber
        self.poundTest = poundTest
        self.leaderDescription = leaderDescription
        self.createdAt = createdAt
    }

    public var displayName: String {
        "\(type.rawValue) \(lineRatingNumber)号 (\(Int(poundTest))lb)"
    }
}

/// 拟饵实体
@Model
public final class Lure {
    public var id: UUID
    public var brand: String
    public var name: String              // 名称 (如: 一击波扒)
    public var category: LureCategory    // 大类
    public var weightGrams: Double       // 自重 (g)
    public var buoyancy: BuoyancyType    // 沉水状态
    public var colorName: String         // 涂装颜色
    public var photoLocalUri: String?    // 本地照片路径
    public var isFavorite: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        brand: String = "",
        name: String,
        category: LureCategory = .minnow,
        weightGrams: Double = 10.0,
        buoyancy: BuoyancyType = .sinking,
        colorName: String = "银色",
        photoLocalUri: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.brand = brand
        self.name = name
        self.category = category
        self.weightGrams = weightGrams
        self.buoyancy = buoyancy
        self.colorName = colorName
        self.photoLocalUri = photoLocalUri
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    public var displayName: String {
        "\(name) (\(Int(weightGrams))g \(buoyancy.rawValue))"
    }
}

/// 装备组合 (Combo: 竿 + 轮 + 线 组合预设)
@Model
public final class TackleCombo {
    public var id: UUID
    public var name: String              // 组合命名 (如: "主力水库泛用套", "溪流微物套")
    public var rod: Rod?
    public var reel: Reel?
    public var line: FishingLine?
    public var isDefault: Bool           // 是否为默认出钓套
    public var totalCastsCount: Int      // 累计使用这套装备抛竿次数
    public var totalFishCaught: Int      // 累计用这套中鱼数量
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        rod: Rod? = nil,
        reel: Reel? = nil,
        line: FishingLine? = nil,
        isDefault: Bool = false,
        totalCastsCount: Int = 0,
        totalFishCaught: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.rod = rod
        self.reel = reel
        self.line = line
        self.isDefault = isDefault
        self.totalCastsCount = totalCastsCount
        self.totalFishCaught = totalFishCaught
        self.createdAt = createdAt
    }
}
