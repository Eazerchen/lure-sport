import AppIntents
import SwiftUI

/// Apple Watch Ultra Action 物理按键快捷意图: 一键标记中鱼
public struct MarkCatchActionIntent: AppIntent {
    public static var title: LocalizedStringResource = "路亚一键中鱼打卡"
    public static var description = IntentDescription("在水边佩戴 Apple Watch 时，单按橙色动作键即可盲操记录中鱼")

    public static var isDiscoverable: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        FishingWorkoutManager.shared.markCatch()
        return .result()
    }
}

/// 快捷意图: 一键标记咬口
public struct MarkBiteActionIntent: AppIntent {
    public static var title: LocalizedStringResource = "路亚一键标记咬口"
    public static var description = IntentDescription("单按动作按键记录就饵咬口信号")

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        FishingWorkoutManager.shared.markBite()
        return .result()
    }
}
