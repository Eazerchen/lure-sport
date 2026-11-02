import Foundation

// MARK: - 装备推荐预设项数据结构

public struct RodPreset: Hashable, Identifiable {
    public var id: String { "\(brand)_\(model)" }
    public let brand: String
    public let model: String
    public let defaultAction: RodAction
    public let minWeight: Double
    public let maxWeight: Double
}

public struct ReelPreset: Hashable, Identifiable {
    public var id: String { "\(brand)_\(model)_\(ratio)" }
    public let brand: String
    public let model: String
    public let type: ReelType
    public let ratio: Double
}

public struct LurePreset: Hashable, Identifiable {
    public var id: String { "\(name)_\(weight)g" }
    public let name: String
    public let category: LureCategory
    public let weight: Double
    public let buoyancy: BuoyancyType
}

// MARK: - 本地离线高频装备词典

public struct TackleDictionary {
    
    // 主流路亚品牌
    public static let popularBrands: [String] = [
        "禧玛诺 (Shimano)",
        "达亿瓦 (Daiwa)",
        "阿布 (Abu Garcia)",
        "梅加巴斯 (Megabass)",
        "杰卡尔 (Jackall)",
        "品钓 (Piscifun)",
        "科尼 (Crony)",
        "卡斯丁 (KastKing)",
        "鱼猎人 (Fish Hunter)",
        "贝克利 (Berkley)"
    ]

    // 高频路亚竿经典型号
    public static let rodPresets: [RodPreset] = [
        RodPreset(brand: "Shimano", model: "Zodias (佐大师)", defaultAction: .ml, minWeight: 4.0, maxWeight: 15.0),
        RodPreset(brand: "Shimano", model: "Poison Adrena", defaultAction: .m, minWeight: 7.0, maxWeight: 21.0),
        RodPreset(brand: "Shimano", model: "Expride", defaultAction: .mh, minWeight: 10.0, maxWeight: 30.0),
        RodPreset(brand: "Daiwa", model: "Tatula (蜘蛛)", defaultAction: .m, minWeight: 5.0, maxWeight: 20.0),
        RodPreset(brand: "Daiwa", model: "Steez (斯蒂兹)", defaultAction: .ml, minWeight: 3.5, maxWeight: 14.0),
        RodPreset(brand: "Daiwa", model: "Rebellion", defaultAction: .m, minWeight: 7.0, maxWeight: 21.0),
        RodPreset(brand: "Abu Garcia", model: "Black Max (黑尊)", defaultAction: .m, minWeight: 5.0, maxWeight: 20.0),
        RodPreset(brand: "Crony", model: "溪流微物溪影", defaultAction: .ul, minWeight: 1.0, maxWeight: 5.0),
        RodPreset(brand: "Piscifun", model: "幻影 Torrent", defaultAction: .m, minWeight: 7.0, maxWeight: 25.0)
    ]

    // 高频路亚轮经典型号
    public static let reelPresets: [ReelPreset] = [
        ReelPreset(brand: "Shimano", model: "Metanium (红蝎/大都会)", type: .baitcaster, ratio: 7.1),
        ReelPreset(brand: "Shimano", model: "Aldebaran BFS (微物轮)", type: .baitcaster, ratio: 7.8),
        ReelPreset(brand: "Shimano", model: "SLX DC (数码刹车)", type: .baitcaster, ratio: 7.2),
        ReelPreset(brand: "Shimano", model: "Stradic (斯泰迪 纺车)", type: .spinning, ratio: 6.0),
        ReelPreset(brand: "Daiwa", model: "Tatula SV TW (小蜘蛛)", type: .baitcaster, ratio: 7.1),
        ReelPreset(brand: "Daiwa", model: "Alphas SV TW", type: .baitcaster, ratio: 7.1),
        ReelPreset(brand: "Daiwa", model: "Steez CT SV TW", type: .baitcaster, ratio: 8.1),
        ReelPreset(brand: "Daiwa", model: "Luvias (纺车轮)", type: .spinning, ratio: 6.2),
        ReelPreset(brand: "Abu Garcia", model: "Revo 5 X", type: .baitcaster, ratio: 7.3)
    ]

    // 高频经典假饵分类模板
    public static let lurePresets: [LurePreset] = [
        LurePreset(name: "经典米诺 (7g 沉水)", category: .minnow, weight: 7.0, buoyancy: .sinking),
        LurePreset(name: "远投悬停米诺 (10g SP)", category: .minnow, weight: 10.0, buoyancy: .suspend),
        LurePreset(name: "水面系波扒 (9g 浮水)", category: .popper, weight: 9.0, buoyancy: .floating),
        LurePreset(name: "水面系铅笔 (12g 浮水)", category: .pencil, weight: 12.0, buoyancy: .floating),
        LurePreset(name: "全泳层金属 VIB (14g)", category: .vib, weight: 14.0, buoyancy: .fastSinking),
        LurePreset(name: "经典 T尾软虫 + 5g 铅头钩", category: .softBait, weight: 8.0, buoyancy: .sinking),
        LurePreset(name: "德州钓组 (7g 子弹铜)", category: .softBait, weight: 10.0, buoyancy: .sinking),
        LurePreset(name: "斜切亮片 (7g 泛用)", category: .spoon, weight: 7.0, buoyancy: .sinking),
        LurePreset(name: "深场铁板 (20g 快沉)", category: .spoon, weight: 20.0, buoyancy: .fastSinking)
    ]

    /// 智能模糊检索推荐
    public static func searchRods(keyword: String) -> [RodPreset] {
        guard !keyword.isEmpty else { return rodPresets }
        return rodPresets.filter {
            $0.brand.localizedCaseInsensitiveContains(keyword) ||
            $0.model.localizedCaseInsensitiveContains(keyword)
        }
    }

    public static func searchReels(keyword: String) -> [ReelPreset] {
        guard !keyword.isEmpty else { return reelPresets }
        return reelPresets.filter {
            $0.brand.localizedCaseInsensitiveContains(keyword) ||
            $0.model.localizedCaseInsensitiveContains(keyword)
        }
    }
}
