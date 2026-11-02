import SwiftUI
import WatchKit

public struct WatchActiveSessionView: View {
    @ObservedObject var workoutManager = FishingWorkoutManager.shared
    @State private var showingStopConfirm = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    
                    // 1. 顶部运动量核心栏: 计时 + 心率
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatDuration(workoutManager.sessionDuration))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.yellow)
                            Text("作钓时长")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                                Text("\(Int(workoutManager.currentHeartRate))")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            Text("BPM 心率")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)

                    Divider().background(Color.gray.opacity(0.4))

                    // 2. 核心大字: 累计抛投数 (Casts)
                    VStack(spacing: 0) {
                        Text("\(workoutManager.totalCastsCount)")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundColor(.cyan)
                            .minimumScaleFactor(0.7)
                        
                        Text("累计抛竿 (CASTS)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan.opacity(0.8))
                    }
                    .padding(.vertical, 2)

                    // 3. 次要指标: 峰值G力 + 消耗卡路里
                    HStack {
                        Label {
                            Text(String(format: "%.1f G", workoutManager.maxCastGForce))
                                .font(.system(size: 12, weight: .semibold))
                        } icon: {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        Label {
                            Text("\(Int(workoutManager.activeCalories)) kcal")
                                .font(.system(size: 12, weight: .semibold))
                        } icon: {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)

                    // 4. 水上盲操大按钮区
                    HStack(spacing: 8) {
                        // 记咬口按钮
                        Button {
                            workoutManager.markBite()
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 16))
                                Text("咬口 (\(workoutManager.recentBitesCount))")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.orange.opacity(0.25))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        // 记中鱼按钮 (超大高亮)
                        Button {
                            workoutManager.markCatch()
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "fish.fill")
                                    .font(.system(size: 18))
                                Text("中鱼 (\(workoutManager.recentCatchesCount))")
                                    .font(.system(size: 13, weight: .black))
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)

                    // 5. 结束作钓
                    Button(role: .destructive) {
                        showingStopConfirm = true
                    } label: {
                        Text("结束出钓")
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 4)
            }
            .confirmationDialog("确定结束本次路亚出钓吗？", isPresented: $showingStopConfirm) {
                Button("结束并保存", role: .destructive) {
                    Task {
                        await workoutManager.stopSession()
                    }
                }
                Button("继续作钓", role: .cancel) {}
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
