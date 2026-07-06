import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: FocusStore
    @State private var selectedPlan: PlanView = .today
    @State private var searchText = ""
    @State private var isTimerFullscreen = false

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
                VStack(spacing: 18) {
                    HeaderView()

                    HStack(alignment: .top, spacing: 18) {
                        PlanSidebar(selectedPlan: $selectedPlan, searchText: $searchText)
                            .frame(width: 244)

                        TaskColumn(selectedPlan: $selectedPlan, searchText: searchText)
                            .frame(width: 360)

                        TimerPanel {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                isTimerFullscreen = true
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        StatsColumn()
                            .frame(width: 238)
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(24)
                .transition(.opacity)
            }
        }
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tomato Reminder")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x232323))

                Text("今日专注 \(store.todayFocusSeconds.hourMinuteText) · \(store.todayFocusSessions) 个番茄")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

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
            .frame(width: 280)
        }
    }
}

private struct PlanSidebar: View {
    @EnvironmentObject private var store: FocusStore
    @Binding var selectedPlan: PlanView
    @Binding var searchText: String
    @FocusState private var searchFocused: Bool

    private let rows: [PlanView] = [.today, .tomorrow, .thisWeek, .planned, .completed, .all]

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
    @State private var newTaskTitle = ""
    @State private var newTaskEstimate = 1
    @State private var newTaskPriority: TaskPriority = .medium
    @State private var newTaskPlan: TaskPlan = .today

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
            }

            VStack(spacing: 10) {
                TextField("输入一个待办事项", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                    .onSubmit(addTask)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("计划")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Picker("计划", selection: $newTaskPlan) {
                            ForEach(TaskPlan.allCases) { plan in
                                Text(plan.title).tag(plan)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 90)

                        Text("番茄")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Stepper("\(newTaskEstimate)", value: $newTaskEstimate, in: 1...12)
                            .labelsHidden()
                            .frame(width: 64)

                        Spacer(minLength: 0)

                        Button(action: addTask) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.accentCircle(color: Color(hex: 0xF05A4F)))
                        .keyboardShortcut(.return, modifiers: [.command])
                        .help("添加任务")
                    }

                    HStack(spacing: 8) {
                        Text("优先级")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Picker("优先级", selection: $newTaskPriority) {
                            ForEach(TaskPriority.allCases) { priority in
                                Text(priority.title).tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
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
        .onAppear {
            newTaskPlan = selectedPlan.defaultTaskPlan
        }
        .onChange(of: selectedPlan) { _, newValue in
            newTaskPlan = newValue.defaultTaskPlan
        }
    }

    private func addTask() {
        let targetPlan = selectedPlan == .completed ? .today : newTaskPlan
        store.addTask(title: newTaskTitle, estimate: newTaskEstimate, priority: newTaskPriority, plan: targetPlan)
        newTaskTitle = ""
        newTaskEstimate = 1
        newTaskPriority = .medium
        newTaskPlan = selectedPlan.defaultTaskPlan

        if selectedPlan == .completed {
            selectedPlan = .today
        }
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

private struct TaskRow: View {
    @EnvironmentObject private var store: FocusStore
    let task: FocusTask

    private var isSelected: Bool {
        store.selectedTaskID == task.id
    }

    private var plan: TaskPlan {
        store.taskPlan(for: task)
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
                    Capsule()
                        .fill(task.priority.color)
                        .frame(width: 7, height: 7)

                    Text("\(task.completedSessions)/\(task.estimate) 番茄")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

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
                    store.markSelectedTaskDone()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.largeCircle(color: Color(hex: 0xE9ECEF), foreground: Color(hex: 0x40444D)))
                .help("完成当前任务")
                .disabled(store.selectedTask == nil)
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
                            store.markSelectedTaskDone()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .buttonStyle(.largeCircle(color: Color(hex: 0xE9ECEF), foreground: Color(hex: 0x40444D), size: 60))
                        .help("完成当前任务")
                        .disabled(store.selectedTask == nil)
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

private struct FocusDots: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<store.longBreakAfter, id: \.self) { index in
                Circle()
                    .fill(index < store.focusCycleCount % store.longBreakAfter ? Color(hex: 0xF05A4F) : Color(hex: 0xD9DDE5))
                    .frame(width: 9, height: 9)
            }
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
