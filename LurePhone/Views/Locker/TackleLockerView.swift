import SwiftUI
import SwiftData

/// iPhone 端装备库大厅 (Tackle Locker)
public struct TackleLockerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TackleCombo.createdAt, order: .reverse) private var combos: [TackleCombo]
    @Query(sort: \Rod.createdAt, order: .reverse) private var rods: [Rod]
    @Query(sort: \Reel.createdAt, order: .reverse) private var reels: [Reel]
    @Query(sort: \Lure.createdAt, order: .reverse) private var lures: [Lure]

    @State private var showingAddCombo = false
    @State private var showingAddLure = false
    @State private var selectedTab = 0

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 分段控制器
                Picker("分类", selection: $selectedTab) {
                    Text("出钓组合 (\(combos.count))").tag(0)
                    Text("假饵盒 (\(lures.count))").tag(1)
                    Text("竿轮配件 (\(rods.count + reels.count))").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // 内容区
                TabView(selection: $selectedTab) {
                    // 1. 出钓组合列表 (Combos)
                    comboListView
                        .tag(0)

                    // 2. 拟饵盒列表 (Lure Box)
                    lureBoxView
                        .tag(1)

                    // 3. 单品竿轮库
                    hardwareListView
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("我的路亚装备库")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddCombo = true
                        } label: {
                            Label("新建出钓组合 (Combo)", systemImage: "plus.circle")
                        }

                        Button {
                            showingAddLure = true
                        } label: {
                            Label("添加假饵至拟饵盒", systemImage: "fish")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCombo) {
                AddComboQuickView()
            }
            .sheet(isPresented: $showingAddLure) {
                AddLureQuickView()
            }
        }
    }

    // MARK: - 子视图: 出钓组合列表
    private var comboListView: some View {
        List {
            if combos.isEmpty {
                ContentUnavailableView(
                    "暂无预设组合",
                    systemImage: "archivebox",
                    description: Text("点击右上角 +，将竿、轮、线搭配为出钓套，作钓时可一键选定。")
                )
            } else {
                ForEach(combos) { combo in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(combo.name)
                                .font(.headline)
                            if combo.isDefault {
                                Text("默认主力套")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            Text("中鱼: \(combo.totalFishCaught)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 12) {
                            Label(combo.rod?.displayName ?? "未选竿", systemImage: "figure.fishing")
                            Label(combo.reel?.displayName ?? "未选轮", systemImage: "gearshape")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(combos[index])
                    }
                }
            }
        }
    }

    // MARK: - 子视图: 拟饵盒
    private var lureBoxView: some View {
        List {
            ForEach(lures) { lure in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lure.name)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text(lure.category.rawValue)
                            Text("\(Int(lure.weightGrams))g")
                            Text(lure.buoyancy.rawValue)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                    if lure.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(lures[index])
                }
            }
        }
    }

    // MARK: - 子视图: 竿轮库
    private var hardwareListView: some View {
        List {
            Section("路亚竿 (Rods)") {
                ForEach(rods) { rod in
                    Text(rod.displayName)
                }
            }
            Section("渔轮 (Reels)") {
                ForEach(reels) { reel in
                    Text(reel.displayName)
                }
            }
        }
    }
}

// MARK: - 快速添加组合弹窗 (带内置联想)

public struct AddComboQuickView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var comboName: String = "主力泛用套"
    @State private var rodSearch: String = ""
    @State private var reelSearch: String = ""
    
    @State private var selectedRodPreset: RodPreset?
    @State private var selectedReelPreset: ReelPreset?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("组合名称") {
                    TextField("例如: 溪流微物套 / 岸抛远投套", text: $comboName)
                }

                Section("快速挑选路亚竿 (支持搜索与联想)") {
                    TextField("输入品牌或型号 (如: Shimano)", text: $rodSearch)
                    let matchedRods = TackleDictionary.searchRods(keyword: rodSearch)
                    ForEach(matchedRods.prefix(4)) { preset in
                        HStack {
                            Text("\(preset.brand) \(preset.model)")
                            Spacer()
                            Text(preset.defaultAction.rawValue)
                                .foregroundColor(.secondary)
                            if selectedRodPreset == preset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRodPreset = preset
                            rodSearch = "\(preset.brand) \(preset.model)"
                        }
                    }
                }

                Section("快速挑选渔轮") {
                    TextField("输入品牌或型号 (如: Tatula)", text: $reelSearch)
                    let matchedReels = TackleDictionary.searchReels(keyword: reelSearch)
                    ForEach(matchedReels.prefix(4)) { preset in
                        HStack {
                            Text("\(preset.brand) \(preset.model)")
                            Spacer()
                            Text("\(preset.ratio):1")
                                .foregroundColor(.secondary)
                            if selectedReelPreset == preset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedReelPreset = preset
                            reelSearch = "\(preset.brand) \(preset.model)"
                        }
                    }
                }
            }
            .navigationTitle("新建出钓组合")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveCombo()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveCombo() {
        // 创建或关联 Rod
        let rod: Rod
        if let preset = selectedRodPreset {
            rod = Rod(brand: preset.brand, modelName: preset.model, action: preset.defaultAction)
        } else {
            rod = Rod(brand: "自定义", modelName: rodSearch.isEmpty ? "通用竿" : rodSearch)
        }
        modelContext.insert(rod)

        // 创建或关联 Reel
        let reel: Reel
        if let preset = selectedReelPreset {
            reel = Reel(brand: preset.brand, modelName: preset.model, type: preset.type, gearRatio: preset.ratio)
        } else {
            reel = Reel(brand: "自定义", modelName: reelSearch.isEmpty ? "通用轮" : reelSearch)
        }
        modelContext.insert(reel)

        // 保存组合
        let combo = TackleCombo(name: comboName, rod: rod, reel: reel, isDefault: true)
        modelContext.insert(combo)
    }
}

// MARK: - 快速添加假饵弹窗
public struct AddLureQuickView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var lureName: String = ""
    @State private var category: LureCategory = .minnow
    @State private var weightG: Double = 10.0
    @State private var buoyancy: BuoyancyType = .sinking

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("假饵预设模板") {
                    ForEach(TackleDictionary.lurePresets.prefix(4)) { preset in
                        Button {
                            lureName = preset.name
                            category = preset.category
                            weightG = preset.weight
                            buoyancy = preset.buoyancy
                        } label: {
                            HStack {
                                Text(preset.name)
                                Spacer()
                                Text("\(Int(preset.weight))g")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section("详细参数") {
                    TextField("假饵名称", text: $lureName)
                    Picker("分类", selection: $category) {
                        ForEach(LureCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    HStack {
                        Text("自重 (克)")
                        Spacer()
                        TextField("克重", value: $weightG, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("沉水属性", selection: $buoyancy) {
                        ForEach(BuoyancyType.allCases, id: \.self) { b in
                            Text(b.rawValue).tag(b)
                        }
                    }
                }
            }
            .navigationTitle("添加拟饵")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let finalName = lureName.isEmpty ? category.rawValue : lureName
                        let lure = Lure(name: finalName, category: category, weightGrams: weightG, buoyancy: buoyancy)
                        modelContext.insert(lure)
                        dismiss()
                    }
                }
            }
        }
    }
}
