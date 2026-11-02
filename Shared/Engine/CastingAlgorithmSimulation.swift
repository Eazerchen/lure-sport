import Foundation

/// 仿真时序数据生成器与算法准确性测试
public struct CastingAlgorithmSimulation {
    
    public static func runTest() {
        print("======== 开始路亚抛投算法仿真测试 ========")
        let detector = CastingDetector(orientation: .castingHand, config: .standard)
        
        var detectedCasts: [CastDetectionResult] = []
        detector.onCastDetected = { result in
            detectedCasts.append(result)
            print("🎣 [检测到有效抛竿!] 峰值加速度: \(String(format: "%.2f", result.peakGForce)) G, 动作历时: \(result.durationMs) ms")
        }

        var simulatedTime = Date()

        // 场景 1: 模拟正常涉水行走的持续摆臂 (5 秒钟，50Hz 采样 = 250 个点)
        print(">> 场景 1: 涉水徒步漫步 (预期: 0 次抛投)...")
        for _ in 0..<250 {
            simulatedTime = simulatedTime.addingTimeInterval(0.02) // 50Hz = 每 20ms 一帧
            // 步行晃动: G 值在 0.9 ~ 1.2 之间微弱起伏
            let walkingAccel = Double.random(in: 0.1...0.3)
            let walkingRot = Double.random(in: 0.2...0.8)
            detector.processSample(
                userAccelX: walkingAccel,
                userAccelY: walkingAccel * 0.5,
                userAccelZ: walkingAccel * 0.2,
                rotX: walkingRot,
                rotY: 0.1,
                rotZ: 0.2,
                timestamp: simulatedTime
            )
        }
        assert(detectedCasts.isEmpty, "错误：徒步晃动被误判为抛竿！")
        print("✅ 场景 1 通过: 徒步未触发任何误判。")

        // 场景 2: 模拟一次标准上手抛 (Overhead Cast)
        print(">> 场景 2: 发生一次标准上手远投 (预期: 成功识别 1 次抛投)...")
        
        // 阶段 2.1: 后摆蓄力 200ms (10 帧)
        for _ in 0..<10 {
            simulatedTime = simulatedTime.addingTimeInterval(0.02)
            detector.processSample(
                userAccelX: 0.2,
                userAccelY: 0.3,
                userAccelZ: 0.1,
                rotX: -2.8, // 强烈的反向俯仰后仰角速度
                rotY: 0.2,
                rotZ: 0.1,
                timestamp: simulatedTime
            )
        }

        // 阶段 2.2: 瞬时向前爆发前挥 160ms (8 帧)，加速度飙升至 3.6G
        for i in 0..<8 {
            simulatedTime = simulatedTime.addingTimeInterval(0.02)
            let burstG = (i < 4) ? Double(i + 1) * 0.9 : (8 - Double(i)) * 0.9
            detector.processSample(
                userAccelX: burstG * 0.7,
                userAccelY: burstG * 0.6,
                userAccelZ: burstG * 0.4, // 合成加速度将达到 ~3.6G
                rotX: 4.8,               // 正向极快旋转
                rotY: 1.2,
                rotZ: 0.5,
                timestamp: simulatedTime
            )
        }

        // 阶段 2.3: 随动减速出线 200ms (10 帧)
        for _ in 0..<10 {
            simulatedTime = simulatedTime.addingTimeInterval(0.02)
            detector.processSample(
                userAccelX: 0.2,
                userAccelY: 0.1,
                userAccelZ: 0.1,
                rotX: 0.5,
                rotY: 0.1,
                rotZ: 0.1,
                timestamp: simulatedTime
            )
        }

        assert(detectedCasts.count == 1, "错误：未成功识别抛竿动作！当前计数: \(detectedCasts.count)")
        print("✅ 场景 2 通过: 精准识别 1 次抛竿，峰值 G 值: \(String(format: "%.2f", detectedCasts.first?.peakGForce ?? 0)) G")
        print("======== 仿真测试全部通过 ========")
    }
}
