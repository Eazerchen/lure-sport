import SwiftUI
import SwiftData

/// Strava 风格路亚运动战报卡片 (支持渲染长图与分享)
public struct SessionSummaryCardView: View {
    public let session: FishingSession
    @Environment(\.dismiss) private var dismiss
    @State private var showingSavedAlert = false

    public init(session: FishingSession) {
        self.session = session
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 战报渲染卡片区域
                    infographicCard
                        .padding(.horizontal, 16)
                    
                    // 底部操作按钮
                    Button {
                        exportCardToPhotos()
                    } label: {
                        Label("保存战报长图至相册", systemImage: "square.and.arrow.down.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("出钓复盘战报")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("战报已保存至系统相册", isPresented: $showingSavedAlert) {
                Button("好", role: .cancel) {}
            }
        }
    }

    // MARK: - 战报主卡片 (被 ImageRenderer 渲染为分享图片)
    private var infographicCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. 卡片头: 品牌与日期
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LURE SPORT TRACKER")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.green)
                    Text(session.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Divider().background(Color.gray.opacity(0.3))

            // 2. 核心大字: 抛投挥竿数 (Strava 大数字风格)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.totalCastsCount)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundColor(.cyan)
                
                Text("TOTAL CASTS 累计抛投")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
            }

            // 3. 核心指标矩阵网格 (2 x 2)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                metricCell(
                    title: "作钓时长",
                    value: formatDuration(session.durationSeconds),
                    icon: "clock.fill",
                    color: .yellow
                )
                metricCell(
                    title: "最高挥竿爆发",
                    value: String(format: "%.1f G", session.maxCastGForce),
                    icon: "bolt.fill",
                    color: .orange
                )
                metricCell(
                    title: "成功中鱼",
                    value: "\(session.totalCatches) 尾",
                    icon: "fish.fill",
                    color: .green
                )
                metricCell(
                    title: "就饵咬口",
                    value: "\(session.totalBites) 次",
                    icon: "hand.tap.fill",
                    color: .orange
                )
                metricCell(
                    title: "卡路里消耗",
                    value: "\(Int(session.activeCaloriesKcal)) kcal",
                    icon: "flame.fill",
                    color: .red
                )
                metricCell(
                    title: "平均心率",
                    value: "\(Int(session.averageHeartRateBpm)) bpm",
                    icon: "heart.fill",
                    color: .pink
                )
            }

            Divider().background(Color.gray.opacity(0.3))

            // 4. 装备标签栏
            if let combo = session.combo {
                VStack(alignment: .leading, spacing: 6) {
                    Text("出钓主力装备组合")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        if let rod = combo.rod {
                            Label(rod.displayName, systemImage: "figure.fishing")
                        }
                        if let reel = combo.reel {
                            Label(reel.displayName, systemImage: "gearshape")
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                }
            }

            // 底部签名
            HStack {
                Spacer()
                Text("Tracked with Apple Watch")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.11, blue: 0.13))
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
    }

    private func metricCell(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) 分钟"
        }
    }

    /// 将卡片渲染为图片并保存至系统相册 (iOS 16+ 原生 ImageRenderer)
    @MainActor
    private func exportCardToPhotos() {
        let renderer = ImageRenderer(content: infographicCard.frame(width: 360))
        renderer.scale = 3.0 // 3倍高清视网膜渲染
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showingSavedAlert = true
        }
    }
}
