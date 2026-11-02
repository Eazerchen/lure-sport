import Foundation
import WatchConnectivity
import SwiftData

/// 跨端数据传输 DTO 载荷
public struct SessionSyncDTO: Codable {
    public let sessionId: UUID
    public let startTime: Date
    public let endTime: Date
    public let totalCastsCount: Int
    public let maxCastGForce: Double
    public let activeCaloriesKcal: Double
    public let avgHeartRate: Double
    public let maxHeartRate: Double
    public let bitesCount: Int
    public let catchesCount: Int

    public init(
        sessionId: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        totalCastsCount: Int,
        maxCastGForce: Double,
        activeCaloriesKcal: Double,
        avgHeartRate: Double,
        maxHeartRate: Double,
        bitesCount: Int,
        catchesCount: Int
    ) {
        self.sessionId = sessionId
        self.startTime = startTime
        self.endTime = endTime
        self.totalCastsCount = totalCastsCount
        self.maxCastGForce = maxCastGForce
        self.activeCaloriesKcal = activeCaloriesKcal
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.bitesCount = bitesCount
        self.catchesCount = catchesCount
    }
}

/// 双端近场蓝牙/Wi-Fi 离线同步服务
public final class WatchSessionSyncService: NSObject, ObservableObject, WCSessionDelegate {
    
    public static let shared = WatchSessionSyncService()

    // 接收到新同步会话的回调 (给 iPhone 端接入 SwiftData 保存)
    public var onSessionReceived: ((SessionSyncDTO) -> Void)?

    override private init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// Watch 端调用: 发送完成的出钓数据包至 iPhone
    public func sendSessionToPhone(_ dto: SessionSyncDTO) {
        guard WCSession.default.activationState == .activated else { return }

        do {
            let data = try JSONEncoder().encode(dto)
            // transferUserInfo 会在后台排队，保证哪怕手机暂时不在身边，靠近后也会可靠投递
            WCSession.default.transferUserInfo(["session_payload": data])
        } catch {
            print("编码出钓同步数据失败: \(error)")
        }
    }

    // MARK: - WCSessionDelegate 回调

    public func session(_ session: WCSession, activationDidCompleteFor activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession 激活出错: \(error.localizedDescription)")
        }
    }

    /// 接收从手表端发送过来的离线数据包
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        guard let data = userInfo["session_payload"] as? Data else { return }
        
        do {
            let dto = try JSONDecoder().decode(SessionSyncDTO.self, from: data)
            DispatchQueue.main.async {
                self.onSessionReceived?(dto)
            }
        } catch {
            print("解析跨端会话数据失败: \(error)")
        }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        // iOS 需要重新激活
        WCSession.default.activate()
    }
    #endif
}
