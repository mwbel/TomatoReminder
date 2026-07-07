import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: FocusStore
    @State private var selectedPlan: PlanView = .today
    @State private var searchText = ""
    @State private var isTimerFullscreen = false
    @State private var isAddItemPresented = false
    @State private var selectedPracticeID: UUID?

    private var selectedPracticeSummary: PracticeSummary? {
        let summaries = store.practiceSummaries(searchText: searchText)
        if let selectedPracticeID, let summary = summaries.first(where: { $0.id == selectedPracticeID }) {
            return summary
        }

        return summaries.first
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xFFF6F0),
                    Color(hex: 0xF3FAF4),
                    Color(hex: 0xF6F7FB)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isTimerFullscreen {
                FullscreenTimerView(isPresented: $isTimerFullscreen)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                GeometryReader { proxy in
                    let referenceWidth: CGFloat = 1320
                    let scale = min(1, proxy.size.width / referenceWidth)
                    let contentWidth = max(proxy.size.width / max(scale, 0.01), referenceWidth)
                    let contentHeight = max(proxy.size.height / max(scale, 0.01), 660)

                    VStack(spacing: 18) {
                        HeaderView(selectedPlan: selectedPlan)

                        HStack(alignment: .top, spacing: 18) {
                            PlanSidebar(selectedPlan: $selectedPlan, searchText: $searchText)
                                .frame(width: 244)

                            Group {
                                if selectedPlan == .practiceStats {
                                    PracticeStatsColumn(
                                        searchText: searchText,
                                        selectedSummaryID: $selectedPracticeID
                                    )
                                } else {
                                    TaskColumn(selectedPlan: $selectedPlan, searchText: searchText) {
                                        isAddItemPresented = true
                                    }
                                }
                            }
                            .frame(width: 360)

                            if selectedPlan == .practiceStats,
                               let practiceSummary = selectedPracticeSummary,
                               practiceSummary.unit == .times {
                                PracticeCounterDetailView(summary: practiceSummary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                TimerPanel {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        isTimerFullscreen = true
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                                StatsColumn()
                                    .frame(width: 238)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .padding(24)
                    .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                }
                .transition(.opacity)
            }

            if isAddItemPresented {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .transition(.opacity)

                AddFocusItemDialog(
                    isPresented: $isAddItemPresented,
                    defaultPlan: selectedPlan == .completed ? .today : selectedPlan.defaultTaskPlan
                )
                .environmentObject(store)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(2)
            }
        }
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var store: FocusStore
    let selectedPlan: PlanView

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tomato Reminder")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x232323))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .allowsTightening(true)

                Text("今日专注 \(store.todayFocusSeconds.hourMinuteText) · \(store.todayFocusSessions) 个番茄")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)
            }
            .layoutPriority(1)

            Spacer()

            if selectedPlan != .practiceStats {
                Picker("模式", selection: Binding(
                    get: { store.selectedMode },
                    set: { store.switchMode($0) }
                )) {
                    ForEach(FocusMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }
        }
    }
}

private struct PlanSidebar: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var selectedPlan: PlanView
    @Binding var searchText: String
    @FocusState private var searchFocused: Bool

    private let rows: [PlanView] = [.today, .tomorrow, .thisWeek, .planned, .completed, .all, .practiceStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color(hex: 0xA8ADB4))

                TextField("搜索", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .semibold))
                    .focused($searchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xB5BAC2))
                    }
                    .buttonStyle(.plain)
                    .help("清空搜索")
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color(hex: 0xEEF0F4).opacity(0.94), in: RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 8) {
                ForEach(rows) { view in
                    PlanSidebarRow(
                        view: view,
                        isSelected: selectedPlan == view,
                        estimatedSeconds: store.estimatedSeconds(for: view),
                        count: store.taskCount(for: view)
                    ) {
                        searchText = ""
                        searchFocused = false
                        selectedPlan = view
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
    }
}

private struct PlanSidebarRow: View {
    let view: PlanView
    let isSelected: Bool
    let estimatedSeconds: Int
    let count: Int
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: view.systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(view.color)
                .frame(width: 24)

            Text(view.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: 0x42454A))
                .lineLimit(1)
                .frame(width: 58, alignment: .leading)

            Spacer()

            Text(estimatedSeconds.compactDurationText)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: 0xA8ADB4))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 54, alignment: .trailing)

            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: 0xA8ADB4))
                .monospacedDigit()
                .frame(minWidth: 18, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            action()
        }
        .onHover { isHovering = $0 }
        .help("切换到\(view.title)")
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.black.opacity(0.07)
        }

        if isHovering {
            return Color.black.opacity(0.04)
        }

        return Color.white.opacity(0.001)
    }
}

private struct TaskColumn: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var selectedPlan: PlanView
    let searchText: String
    let onAddItem: () -> Void

    private var visibleTasks: [FocusTask] {
        store.filteredTasks(for: selectedPlan, searchText: searchText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(selectedPlan.title, systemImage: selectedPlan.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button {
                    store.clearCompletedTasks()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plainIcon)
                .help("清理已完成任务")
                .disabled(!store.tasks.contains(where: \.isDone))

                Button(action: onAddItem) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.accentCircle(color: Color(hex: 0xF05A4F)))
                .help("添加番茄钟、习惯或目标")
            }

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(visibleTasks) { task in
                        TaskRow(task: task)
                    }

                    if visibleTasks.isEmpty {
                        EmptyPlanView(selectedPlan: selectedPlan, searchText: searchText)
                            .padding(.top, 48)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
    }
}

private struct PracticeStatsColumn: View {
    @EnvironmentObject private var store: FocusStore
    let searchText: String
    @Binding var selectedSummaryID: UUID?
    @State private var isCreatePracticePresented = false
    @State private var isDailyAddPresented = false
    @State private var isRenamePracticePresented = false
    @State private var isDeletePracticePresented = false

    private var summaries: [PracticeSummary] {
        store.practiceSummaries(searchText: searchText)
    }

    private var summaryIDs: [UUID] {
        summaries.map(\.id)
    }

    private var selectedSummary: PracticeSummary? {
        if let selectedSummaryID, let summary = summaries.first(where: { $0.id == selectedSummaryID }) {
            return summary
        }

        return summaries.first
    }

    private var todayTotal: Int {
        summaries.reduce(0) { $0 + $1.today }
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("功课统计", systemImage: "chart.bar.xaxis")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    Button {
                        isCreatePracticePresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.accentCircle(color: Color(hex: 0xB38B59)))
                    .help("创建功课")
                }

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        PracticeOverviewTile(title: "今日总打卡", value: "\(todayTotal)")
                        PracticeOverviewTile(title: "功课数", value: "\(summaries.count)")
                    }

                    if let selectedSummary {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(spacing: 6) {
                                        Text(selectedSummary.title)
                                            .font(.system(size: 18, weight: .heavy))
                                            .foregroundStyle(Color(hex: 0x2D3138))
                                            .lineLimit(1)

                                        Button {
                                            selectedSummaryID = selectedSummary.id
                                            isRenamePracticePresented = true
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .buttonStyle(.plainIcon)
                                        .help("修改功课名称")

                                        Button {
                                            selectedSummaryID = selectedSummary.id
                                            isDeletePracticePresented = true
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.plainIcon)
                                        .help("删除功课")
                                    }

                                    Text("\(selectedSummary.kind.shortTitle) · 单位：\(selectedSummary.unitTitle)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(selectedSummary.today)")
                                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(hex: 0x7D828B))
                                    .monospacedDigit()
                            }

                            HStack(spacing: 0) {
                                PracticeMetricCell(title: "周", value: selectedSummary.week)
                                Divider().frame(height: 30)
                                PracticeMetricCell(title: "月", value: selectedSummary.month)
                                Divider().frame(height: 30)
                                PracticeMetricCell(title: "年", value: selectedSummary.year)
                                Divider().frame(height: 30)
                                PracticeMetricCell(title: "总", value: selectedSummary.total)
                            }

                            Button {
                                selectedSummaryID = selectedSummary.id
                                isDailyAddPresented = true
                            } label: {
                                Label("当日添加", systemImage: "plus.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.quiet)
                        }
                        .padding(14)
                        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.72), lineWidth: 1)
                        )
                    }
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                            PracticeStatsRow(
                                rank: index + 1,
                                summary: summary,
                                isSelected: selectedSummary?.id == summary.id,
                                color: practiceRowColor(at: index)
                            ) {
                                selectedSummaryID = summary.id
                            }
                        }

                        if summaries.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 34, weight: .medium))
                                    .foregroundStyle(Color(hex: 0xC4CAD3))

                                Text(searchText.isEmpty ? "还没有功课记录" : "没有匹配的功课")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)

                                Button("创建功课") {
                                    isCreatePracticePresented = true
                                }
                                .buttonStyle(.quiet)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(16)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )

            if isCreatePracticePresented {
                Color.black.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                PracticeCreateDialog(isPresented: $isCreatePracticePresented)
                    .environmentObject(store)
                    .padding(18)
            }

            if isRenamePracticePresented, let selectedSummary {
                Color.black.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                PracticeRenameDialog(
                    isPresented: $isRenamePracticePresented,
                    taskID: selectedSummary.id,
                    currentTitle: selectedSummary.title
                )
                .environmentObject(store)
                .padding(18)
            }

            if isDeletePracticePresented, let selectedSummary {
                Color.black.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                PracticeDeleteDialog(
                    isPresented: $isDeletePracticePresented,
                    summary: selectedSummary
                ) {
                    selectedSummaryID = nil
                }
                .environmentObject(store)
                .padding(18)
            }

            if isDailyAddPresented, let selectedSummary {
                Color.black.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                PracticeDailyAddDialog(
                    isPresented: $isDailyAddPresented,
                    summary: selectedSummary
                )
                .environmentObject(store)
                .padding(18)
            }
        }
        .onAppear {
            syncSelection()
        }
        .onChange(of: summaryIDs) { _, _ in
            syncSelection()
        }
    }

    private func practiceRowColor(at index: Int) -> Color {
        let colors = [
            Color(hex: 0xC7BBB8),
            Color(hex: 0xAEBEC0),
            Color(hex: 0xAAA5B0),
            Color(hex: 0x8FA0B2),
            Color(hex: 0x918EA5),
            Color(hex: 0x9EA786)
        ]
        return colors[index % colors.count]
    }

    private func syncSelection() {
        guard !summaries.isEmpty else {
            selectedSummaryID = nil
            return
        }

        if let selectedSummaryID,
           summaries.contains(where: { $0.id == selectedSummaryID }) {
            return
        }

        selectedSummaryID = summaries.first?.id
    }
}

private struct PracticeOverviewTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x2D3138))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct PracticeMetricCell: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("\(value)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x7D828B))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PracticeCounterDetailView: View {
    @EnvironmentObject private var store: FocusStore
    let summary: PracticeSummary
    @State private var isDailyAddPresented = false
    @State private var isRenamePracticePresented = false
    @State private var isDeletePracticePresented = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(summary.title)
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x1F2329))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text("计数目标 · 单位：\(summary.unitTitle)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Button {
                            isRenamePracticePresented = true
                        } label: {
                            Label("编辑名称", systemImage: "pencil")
                        }
                        .buttonStyle(.quiet)

                        Button {
                            isDailyAddPresented = true
                        } label: {
                            Label("当日添加", systemImage: "plus.circle")
                        }
                        .buttonStyle(.quiet)

                        Button {
                            isDeletePracticePresented = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        .buttonStyle(.quiet)
                    }
                }

                HStack(spacing: 0) {
                    PracticeMetricCell(title: "周", value: summary.week)
                    Divider().frame(height: 36)
                    PracticeMetricCell(title: "月", value: summary.month)
                    Divider().frame(height: 36)
                    PracticeMetricCell(title: "年", value: summary.year)
                    Divider().frame(height: 36)
                    PracticeMetricCell(title: "总", value: summary.total)
                }
                .padding(.vertical, 14)
                .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.72), lineWidth: 1)
                )

                Spacer(minLength: 18)

                VStack(spacing: 18) {
                    Text("\(summary.today)")
                        .font(.system(size: 92, weight: .light, design: .rounded))
                        .foregroundStyle(Color(hex: 0x7D828B))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    CounterGlyphView()
                        .frame(width: 260, height: 260)

                    Text("今日已完成 \(summary.today) \(summary.unitTitle)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 18)
            }
            .padding(30)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )

            if isRenamePracticePresented {
                Color.black.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                PracticeRenameDialog(
                    isPresented: $isRenamePracticePresented,
                    taskID: summary.id,
                    currentTitle: summary.title
                )
                .environmentObject(store)
                .frame(width: 360)
            }

            if isDeletePracticePresented {
                Color.black.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                PracticeDeleteDialog(
                    isPresented: $isDeletePracticePresented,
                    summary: summary
                )
                .environmentObject(store)
                .frame(width: 360)
            }

            if isDailyAddPresented {
                Color.black.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                PracticeDailyAddDialog(
                    isPresented: $isDailyAddPresented,
                    summary: summary
                )
                .environmentObject(store)
                .frame(width: 360)
            }
        }
    }
}

private struct CounterGlyphView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: 0xCDBA82).opacity(0.24), lineWidth: 2)
                .frame(width: 230, height: 230)

            Circle()
                .stroke(Color(hex: 0xCDBA82).opacity(0.18), lineWidth: 2)
                .frame(width: 154, height: 154)

            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(Color(hex: 0xCDBA82).opacity(0.16))
                    .frame(width: 2, height: 70)
                    .offset(y: -58)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            Circle()
                .fill(Color(hex: 0xF4F1EA).opacity(0.9))
                .frame(width: 84, height: 84)

            Image(systemName: "plus")
                .font(.system(size: 42, weight: .ultraLight))
                .foregroundStyle(Color(hex: 0xB38B59).opacity(0.54))
        }
    }
}

private struct PracticeDeleteDialog: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var isPresented: Bool
    let summary: PracticeSummary
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(spacing: 18) {
            Text("删除功课")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color(hex: 0x1F2329))

            Text("确定删除“\(summary.title)”吗？它的手动打卡记录也会一起删除。")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.quiet)

                Spacer(minLength: 12)

                Button {
                    store.deletePractice(taskID: summary.id)
                    onDelete()
                    isPresented = false
                } label: {
                    Label("删除", systemImage: "trash")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(Color(hex: 0xF05A4F), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
    }
}

private struct PracticeStatsRow: View {
    let rank: Int
    let summary: PracticeSummary
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Text("\(rank)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.92), lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(summary.title)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("日 \(summary.today) / 总 \(summary.total) \(summary.unitTitle)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: summary.kind.systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
            }
            .padding(.horizontal, 12)
            .frame(height: 82)
            .background(color.opacity(isSelected ? 1 : 0.88), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? .white.opacity(0.95) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PracticeCreateDialog: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var unit: FocusGoalUnit = .times

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("创建功课")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color(hex: 0x1F2329))

            TextField("请输入功课名称", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: 0xDFE3EA), lineWidth: 1)
                )
                .onSubmit(create)

            Picker("单位", selection: $unit) {
                ForEach(FocusGoalUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            HStack(spacing: 0) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.quiet)

                Spacer(minLength: 12)

                Button("确定") {
                    create()
                }
                .buttonStyle(.quiet)
                .disabled(!canCreate)
            }
        }
        .padding(22)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
    }

    private func create() {
        guard canCreate else { return }
        store.addPractice(title: title, unit: unit)
        isPresented = false
    }
}

private struct PracticeRenameDialog: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var isPresented: Bool
    let taskID: UUID
    let currentTitle: String
    @State private var title = ""

    private var canRename: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("修改功课名称")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color(hex: 0x1F2329))

            TextField("请输入功课名称", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: 0xDFE3EA), lineWidth: 1)
                )
                .onSubmit(rename)

            HStack(spacing: 0) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.quiet)

                Spacer(minLength: 12)

                Button("确定") {
                    rename()
                }
                .buttonStyle(.quiet)
                .disabled(!canRename)
            }
        }
        .padding(22)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        .onAppear {
            title = currentTitle
        }
    }

    private func rename() {
        guard canRename else { return }
        store.renamePractice(taskID: taskID, title: title)
        isPresented = false
    }
}

private struct PracticeDailyAddDialog: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var isPresented: Bool
    let summary: PracticeSummary
    @State private var amount = 1

    var body: some View {
        VStack(spacing: 18) {
            Text("当日添加")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color(hex: 0x1F2329))

            Text(summary.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            TextField("数量", value: $amount, format: .number)
                .textFieldStyle(.plain)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: 0xDFE3EA), lineWidth: 1)
                )
                .onSubmit(add)

            Text("单位：\(summary.unitTitle)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.quiet)

                Spacer(minLength: 12)

                Button("确定") {
                    add()
                }
                .buttonStyle(.quiet)
            }
        }
        .padding(22)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
    }

    private func add() {
        store.addPracticeEntry(taskID: summary.id, amount: amount)
        isPresented = false
    }
}

private struct EmptyPlanView: View {
    let selectedPlan: PlanView
    let searchText: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: searchText.isEmpty ? selectedPlan.systemImage : "magnifyingglass")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color(hex: 0xC4CAD3))

            Text(searchText.isEmpty ? "这里还没有任务" : "没有匹配的任务")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AddFocusItemDialog: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var isPresented: Bool
    let defaultPlan: TaskPlan

    @State private var kind: FocusItemKind = .pomodoro
    @State private var title = ""
    @State private var plan: TaskPlan = .today
    @State private var priority: TaskPriority = .medium
    @State private var estimate = 1
    @State private var timingStyle: FocusTimingStyle = .countdown
    @State private var durationMinutes = 25
    @State private var targetAmount = 1
    @State private var targetUnit: FocusGoalUnit = .times
    @State private var habitFrequency: HabitFrequency = .daily
    @State private var useDeadline = true
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    private var dialogTitle: String {
        switch kind {
        case .pomodoro: return "添加待办"
        case .habit: return "添加习惯养成"
        case .goal: return "添加目标"
        }
    }

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .black))
                }
                .buttonStyle(.plain)
                .help("取消")

                Spacer()

                Text(dialogTitle)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x1F2329))

                Spacer()

                Button(action: createItem) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .black))
                }
                .buttonStyle(.plain)
                .disabled(!canCreate)
                .help("保存")
            }
            .padding(.horizontal, 30)
            .frame(height: 74)
            .background(Color(hex: 0xF5F6F8))

            VStack(spacing: 22) {
                Picker("类型", selection: $kind) {
                    ForEach(FocusItemKind.allCases) { itemKind in
                        Text(itemKind.title).tag(itemKind)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                TextField("请输入事项名称", text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: 0xDFE3EA), lineWidth: 1)
                    )
                    .onSubmit(createItem)

                kindSpecificFields

                VStack(alignment: .leading, spacing: 14) {
                    Text("最后一步，设置单次专注的时长：")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x4D5360))

                    HStack(spacing: 12) {
                        ForEach(FocusTimingStyle.allCases) { style in
                            TimingStyleChip(
                                title: style.title,
                                isSelected: timingStyle == style
                            ) {
                                timingStyle = style
                            }
                        }
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(durationMinutes) 分钟")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(Color(hex: 0x23A8E0))
                                .padding(.horizontal, 14)
                                .frame(height: 34)
                                .background(Color(hex: 0xEAF8FE), in: Capsule())

                            Slider(
                                value: Binding(
                                    get: { Double(durationMinutes) },
                                    set: { durationMinutes = Int($0.rounded()) }
                                ),
                                in: 1...120,
                                step: 1
                            )
                            .tint(Color(hex: 0x23A8E0))
                        }

                        Button {
                            durationMinutes = 25
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .buttonStyle(.largeCircle(color: Color(hex: 0xEAF8FE), foreground: Color(hex: 0x23A8E0), size: 48))
                        .help("恢复 25 分钟")
                    }
                }

                Picker("计划", selection: $plan) {
                    ForEach(TaskPlan.allCases) { plan in
                        Text(plan.title).tag(plan)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Button("更多设置") {}
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(hex: 0x23A8E0))
                    .font(.system(size: 17, weight: .semibold))
                    .disabled(true)
            }
            .padding(.horizontal, 42)
            .padding(.vertical, 28)
        }
        .frame(width: 620)
        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 28, y: 14)
        .onAppear {
            plan = defaultPlan
            durationMinutes = store.focusSeconds / 60
        }
        .onChange(of: kind) { _, newKind in
            switch newKind {
            case .pomodoro:
                timingStyle = .countdown
                targetUnit = .times
                targetAmount = max(estimate, 1)
            case .habit:
                timingStyle = .countdown
                targetUnit = .times
                targetAmount = 1
            case .goal:
                timingStyle = .countdown
                targetUnit = .minutes
                targetAmount = max(durationMinutes, 25)
            }
        }
    }

    @ViewBuilder
    private var kindSpecificFields: some View {
        switch kind {
        case .pomodoro:
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Label("番茄数量", systemImage: "timer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x5A6170))

                    Stepper("\(estimate)", value: $estimate, in: 1...24)
                        .frame(width: 104)

                    Spacer()

                    Picker("优先级", selection: $priority) {
                        ForEach(TaskPriority.allCases) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 150)
                }
            }
        case .habit:
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text("我想")
                        .font(.system(size: 19, weight: .semibold))

                    Picker("频率", selection: $habitFrequency) {
                        ForEach(HabitFrequency.allCases) { frequency in
                            Text(frequency.title).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 110)

                    Text("完成")
                        .font(.system(size: 19, weight: .semibold))

                    TextField("完成量", value: $targetAmount, format: .number)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .frame(width: 92, height: 38)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: 0xDFE3EA), lineWidth: 1)
                        )

                    Picker("单位", selection: $targetUnit) {
                        ForEach(FocusGoalUnit.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 82)

                    Spacer()
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color(hex: 0x4D5360))
        case .goal:
            VStack(alignment: .leading, spacing: 14) {
                Toggle("设置截止日期", isOn: $useDeadline)
                    .font(.system(size: 15, weight: .semibold))

                HStack(spacing: 12) {
                    Text("我想在")
                        .font(.system(size: 19, weight: .semibold))

                    if useDeadline {
                        DatePicker("", selection: $deadline, displayedComponents: .date)
                            .labelsHidden()
                            .frame(width: 146)
                    } else {
                        Text("不设截止日期")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: 0x23A8E0))
                    }

                    Text("之前")
                        .font(.system(size: 19, weight: .semibold))

                    Spacer()
                }

                HStack(spacing: 12) {
                    Text("一共完成")
                        .font(.system(size: 19, weight: .semibold))

                    TextField("完成量", value: $targetAmount, format: .number)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .frame(width: 112, height: 38)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: 0xDFE3EA), lineWidth: 1)
                        )

                    Picker("单位", selection: $targetUnit) {
                        ForEach(FocusGoalUnit.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 90)

                    Spacer()
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color(hex: 0x4D5360))
        }
    }

    private func createItem() {
        guard canCreate else { return }

        let normalizedTarget = max(1, targetAmount)
        let normalizedEstimate: Int

        switch kind {
        case .pomodoro:
            normalizedEstimate = estimate
        case .habit, .goal:
            normalizedEstimate = targetUnit == .times ? normalizedTarget : max(1, normalizedTarget / max(durationMinutes, 1))
        }

        store.addTask(
            title: title,
            estimate: normalizedEstimate,
            priority: priority,
            plan: plan,
            kind: kind,
            timingStyle: timingStyle,
            durationSeconds: durationMinutes * 60,
            targetAmount: kind == .pomodoro ? nil : normalizedTarget,
            targetUnit: kind == .pomodoro ? nil : targetUnit,
            habitFrequency: kind == .habit ? habitFrequency : nil,
            deadline: kind == .goal && useDeadline ? deadline : nil
        )
        isPresented = false
    }
}

private struct TimingStyleChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isSelected ? Color(hex: 0x23A8E0) : Color(hex: 0x1F2329))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color(hex: 0xEAF8FE) : Color(hex: 0xF1F2F4), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct TaskRow: View {
    @EnvironmentObject private var store: FocusStore
    let task: FocusTask

    private var isSelected: Bool {
        store.selectedTaskID == task.id
    }

    private var plan: TaskPlan {
        store.taskPlan(for: task)
    }

    private var kind: FocusItemKind {
        store.itemKind(for: task)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                store.toggleTaskDone(task)
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(task.isDone ? Color(hex: 0x2E9E73) : .secondary)
            }
            .buttonStyle(.plain)
            .help(task.isDone ? "标记为未完成" : "标记完成")

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(task.isDone ? .secondary : Color(hex: 0x242424))
                    .strikethrough(task.isDone)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Label(kind.shortTitle, systemImage: kind.systemImage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(kind.color)
                        .padding(.horizontal, 7)
                        .frame(height: 18)
                        .background(kind.color.opacity(0.12), in: Capsule())

                    Text(store.taskSummary(for: task))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Menu {
                        ForEach(TaskPlan.allCases) { plan in
                            Button {
                                store.moveTask(task, to: plan)
                            } label: {
                                Label(plan.title, systemImage: plan == self.plan ? "checkmark" : "calendar")
                            }
                        }
                    } label: {
                        Text(plan.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(plan.color)
                            .padding(.horizontal, 7)
                            .frame(height: 18)
                            .background(plan.color.opacity(0.12), in: Capsule())
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("调整计划")

                    Stepper("", onIncrement: {
                        store.incrementEstimate(for: task, by: 1)
                    }, onDecrement: {
                        store.incrementEstimate(for: task, by: -1)
                    })
                    .labelsHidden()
                    .controlSize(.mini)
                    .frame(width: 42)
                }
            }

            Spacer(minLength: 4)

            Button {
                store.selectTask(task)
            } label: {
                Image(systemName: isSelected ? "play.fill" : "play")
                    .font(.system(size: 13, weight: .bold))
            }
            .buttonStyle(.accentCircle(color: isSelected ? Color(hex: 0xF05A4F) : Color(hex: 0xD9DDE5)))
            .help("设为当前任务")
            .disabled(task.isDone)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: 0xFFF1EC) : .white.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(hex: 0xF05A4F).opacity(0.55) : .white.opacity(0.45), lineWidth: 1)
        )
    }
}

private struct TimerPanel: View {
    @EnvironmentObject private var store: FocusStore
    var onEnterFullscreen: () -> Void = {}

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()

                Button(action: onEnterFullscreen) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.plainIcon)
                .help("全屏计时")
            }

            VStack(spacing: 6) {
                Text(store.selectedMode.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(store.selectedMode.accent)

                Text(store.selectedMode.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ZStack {
                ProgressRing(progress: store.progress, color: store.selectedMode.accent)
                    .frame(width: 268, height: 268)

                VStack(spacing: 10) {
                    Text(store.remainingSeconds.timerText)
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: 0x222222))

                    Text(store.selectedTask?.title ?? "选择一个任务开始")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 210)
                }
            }
            .padding(.vertical, 8)

            InspirationTextView(text: store.currentInspirationText, maxWidth: 340)

            HStack(spacing: 14) {
                Button {
                    store.resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.largeCircle(color: Color(hex: 0xE9ECEF), foreground: Color(hex: 0x40444D)))
                .help("重置")

                Button {
                    store.toggleTimer()
                } label: {
                    Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                }
                .buttonStyle(.largeCircle(color: store.selectedMode.accent, foreground: .white, size: 72))
                .help(store.isRunning ? "暂停" : "开始")

                Button {
                    store.finishCurrentIntervalNow()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.largeCircle(color: Color(hex: 0xE9ECEF), foreground: Color(hex: 0x40444D)))
                .help(store.isRunning ? "完成当前计时" : "完成当前任务")
                .disabled(!store.isRunning && store.selectedTask == nil)
            }

            FocusDots()

            Spacer(minLength: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(22)
        .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
    }
}

private struct FullscreenTimerView: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var isPresented: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(max(proxy.size.width * 0.32, 360), min(proxy.size.height * 0.56, 560))

            VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                    }
                    .buttonStyle(.plainIcon)
                    .help("退出全屏计时")

                    Spacer()

                    Picker("模式", selection: Binding(
                        get: { store.selectedMode },
                        set: { store.switchMode($0) }
                    )) {
                        ForEach(FocusMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                }
                .padding(.horizontal, 34)
                .padding(.top, 28)

                Spacer(minLength: 12)

                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text(store.selectedMode.title)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(store.selectedMode.accent)

                        Text(store.selectedMode.subtitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    ZStack {
                        ProgressRing(progress: store.progress, color: store.selectedMode.accent, lineWidth: 24)
                            .frame(width: side, height: side)

                        VStack(spacing: 14) {
                            Text(store.remainingSeconds.timerText)
                                .font(.system(size: max(side * 0.18, 70), weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Color(hex: 0x222222))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Text(store.selectedTask?.title ?? "选择一个任务开始")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: min(side * 0.72, 360))
                        }
                    }

                    InspirationTextView(text: store.currentInspirationText, maxWidth: min(max(proxy.size.width * 0.56, 560), 820), fontSize: 18)

                    HStack(spacing: 20) {
                        Button {
                            store.resetTimer()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .buttonStyle(.largeCircle(color: Color(hex: 0xE9ECEF), foreground: Color(hex: 0x40444D), size: 60))
                        .help("重置")

                        Button {
                            store.toggleTimer()
                        } label: {
                            Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 30, weight: .bold))
                        }
                        .buttonStyle(.largeCircle(color: store.selectedMode.accent, foreground: .white, size: 88))
                        .help(store.isRunning ? "暂停" : "开始")

                        Button {
                            store.finishCurrentIntervalNow()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .buttonStyle(.largeCircle(color: Color(hex: 0xE9ECEF), foreground: Color(hex: 0x40444D), size: 60))
                        .help(store.isRunning ? "完成当前计时" : "完成当前任务")
                        .disabled(!store.isRunning && store.selectedTask == nil)
                    }

                    FocusDots()
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 22)
            }
        }
        .padding(24)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
        .padding(24)
    }
}

private struct InspirationTextView: View {
    let text: String?
    var maxWidth: CGFloat
    var fontSize: CGFloat = 14

    var body: some View {
        if let text, !text.isEmpty {
            Text(text)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(Color(hex: 0x555B64))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .lineLimit(nil)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(maxWidth: maxWidth)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(10)
                .background(Color.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )
        }
    }
}

private struct FocusDots: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                ForEach(0..<store.longBreakAfter, id: \.self) { index in
                    Circle()
                        .fill(index < store.focusCycleCount % store.longBreakAfter ? Color(hex: 0xF05A4F) : Color(hex: 0xD9DDE5))
                        .frame(width: 9, height: 9)
                }
            }

            Text("长休息进度 \(store.focusCycleCount % store.longBreakAfter)/\(store.longBreakAfter)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: 0xA5ABB5))
        }
        .accessibilityLabel("长休息前番茄进度")
    }
}

private struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let innerSide = max(side - lineWidth * 3.4, 0)

            ZStack {
                Circle()
                    .stroke(Color(hex: 0xECEFF3), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: progress)

                Circle()
                    .fill(.white.opacity(0.72))
                    .frame(width: innerSide, height: innerSide)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct StatsColumn: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        VStack(spacing: 14) {
            MetricCard(
                title: "今日专注",
                value: store.todayFocusSeconds.hourMinuteText,
                systemImage: "flame.fill",
                color: Color(hex: 0xF05A4F)
            )

            MetricCard(
                title: "完成番茄",
                value: "\(store.todayFocusSessions)",
                systemImage: "timer",
                color: Color(hex: 0x2E9E73)
            )

            SettingsCard()

            Button {
                store.clearTodaySessions()
            } label: {
                Label("清空今日记录", systemImage: "calendar.badge.minus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.quiet)
            .disabled(store.todayFocusSessions == 0)

            Spacer()
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(color, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x222222))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()
        }
        .padding(14)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
    }
}

private struct SettingsCard: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("设置", systemImage: "slider.horizontal.3")
                .font(.system(size: 16, weight: .semibold))

            DurationStepper(title: "番茄", seconds: $store.focusSeconds, color: Color(hex: 0xF05A4F))
            DurationStepper(title: "短休", seconds: $store.shortBreakSeconds, color: Color(hex: 0x2E9E73))
            DurationStepper(title: "长休", seconds: $store.longBreakSeconds, color: Color(hex: 0x3E7CB1))

            Divider()

            Stepper("长休间隔 \(store.longBreakAfter)", value: Binding(
                get: { store.longBreakAfter },
                set: { store.setLongBreakAfter($0) }
            ), in: 2...8)

            Toggle("自动开始休息", isOn: $store.autoStartBreaks)
            Toggle("自动开始专注", isOn: $store.autoStartFocus)
            Toggle("结束提醒音", isOn: $store.playFinishSound)
        }
        .font(.system(size: 13, weight: .medium))
        .padding(14)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
    }
}

private struct DurationStepper: View {
    let title: String
    @Binding var seconds: Int
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
            Spacer()

            Stepper("\(seconds / 60) 分钟", value: Binding(
                get: { seconds / 60 },
                set: { seconds = min(max($0 * 60, 60), 120 * 60) }
            ), in: 1...120)
            .frame(width: 112)
        }
    }
}

private struct PlainIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .background(configuration.isPressed ? Color.black.opacity(0.08) : Color.black.opacity(0.04), in: Circle())
    }
}

private struct AccentCircleButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1), in: Circle())
    }
}

private struct LargeCircleButtonStyle: ButtonStyle {
    let color: Color
    let foreground: Color
    let size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(color.opacity(configuration.isPressed ? 0.78 : 1), in: Circle())
            .shadow(color: color.opacity(0.24), radius: 10, y: 5)
    }
}

private struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(hex: 0x40444D))
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(configuration.isPressed ? Color.black.opacity(0.08) : .white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
    }
}

private extension ButtonStyle where Self == PlainIconButtonStyle {
    static var plainIcon: PlainIconButtonStyle { PlainIconButtonStyle() }
}

private extension ButtonStyle where Self == AccentCircleButtonStyle {
    static func accentCircle(color: Color) -> AccentCircleButtonStyle {
        AccentCircleButtonStyle(color: color)
    }
}

private extension ButtonStyle where Self == LargeCircleButtonStyle {
    static func largeCircle(color: Color, foreground: Color, size: CGFloat = 48) -> LargeCircleButtonStyle {
        LargeCircleButtonStyle(color: color, foreground: foreground, size: size)
    }
}

private extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: QuietButtonStyle { QuietButtonStyle() }
}
