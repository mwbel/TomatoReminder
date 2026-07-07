import AppKit
import Foundation
import SwiftUI
import UserNotifications

enum FocusMode: String, CaseIterable, Codable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "专注"
        case .shortBreak: return "短休息"
        case .longBreak: return "长休息"
        }
    }

    var subtitle: String {
        switch self {
        case .focus: return "进入一个番茄"
        case .shortBreak: return "离开屏幕一下"
        case .longBreak: return "补一段恢复时间"
        }
    }

    var accent: Color {
        switch self {
        case .focus: return Color(hex: 0xF05A4F)
        case .shortBreak: return Color(hex: 0x2E9E73)
        case .longBreak: return Color(hex: 0x3E7CB1)
        }
    }

    var defaultSeconds: Int {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }

    var color: Color {
        switch self {
        case .low: return Color(hex: 0x7FB069)
        case .medium: return Color(hex: 0xF2B84B)
        case .high: return Color(hex: 0xE05B52)
        }
    }
}

enum TaskPlan: String, CaseIterable, Codable, Identifiable {
    case today
    case tomorrow
    case thisWeek
    case planned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "今天"
        case .tomorrow: return "明天"
        case .thisWeek: return "本周"
        case .planned: return "稍后"
        }
    }

    var color: Color {
        switch self {
        case .today: return Color(hex: 0x28B44B)
        case .tomorrow: return Color(hex: 0xFF6B2C)
        case .thisWeek: return Color(hex: 0x7C58FF)
        case .planned: return Color(hex: 0x148BFF)
        }
    }
}

enum PlanView: String, CaseIterable, Identifiable {
    case today
    case tomorrow
    case thisWeek
    case planned
    case completed
    case all
    case practiceStats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "今天"
        case .tomorrow: return "明天"
        case .thisWeek: return "本周"
        case .planned: return "已计划"
        case .completed: return "已完成"
        case .all: return "任务"
        case .practiceStats: return "功课统计"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "sun.max"
        case .tomorrow: return "sunset"
        case .thisWeek: return "calendar"
        case .planned: return "calendar.badge.checkmark"
        case .completed: return "checkmark.circle"
        case .all: return "tray"
        case .practiceStats: return "chart.bar.xaxis"
        }
    }

    var color: Color {
        switch self {
        case .today: return Color(hex: 0x28B44B)
        case .tomorrow: return Color(hex: 0xFF6B2C)
        case .thisWeek: return Color(hex: 0x7C58FF)
        case .planned: return Color(hex: 0x148BFF)
        case .completed: return Color(hex: 0x7D8697)
        case .all: return Color(hex: 0x148BFF)
        case .practiceStats: return Color(hex: 0xB38B59)
        }
    }

    var defaultTaskPlan: TaskPlan {
        switch self {
        case .today: return .today
        case .tomorrow: return .tomorrow
        case .thisWeek: return .thisWeek
        case .planned: return .planned
        case .completed, .all, .practiceStats: return .today
        }
    }
}

enum FocusItemKind: String, CaseIterable, Codable, Identifiable {
    case pomodoro
    case habit
    case goal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pomodoro: return "普通番茄钟"
        case .habit: return "定习惯"
        case .goal: return "目标"
        }
    }

    var shortTitle: String {
        switch self {
        case .pomodoro: return "番茄"
        case .habit: return "习惯"
        case .goal: return "目标"
        }
    }

    var systemImage: String {
        switch self {
        case .pomodoro: return "timer"
        case .habit: return "repeat.circle"
        case .goal: return "flag.checkered"
        }
    }

    var color: Color {
        switch self {
        case .pomodoro: return Color(hex: 0xF05A4F)
        case .habit: return Color(hex: 0x23A8E0)
        case .goal: return Color(hex: 0x7C58FF)
        }
    }
}

enum FocusTimingStyle: String, CaseIterable, Codable, Identifiable {
    case countdown
    case countUp
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countdown: return "倒计时"
        case .countUp: return "正向计时"
        case .none: return "不计时"
        }
    }
}

enum FocusGoalUnit: String, CaseIterable, Codable, Identifiable {
    case minutes
    case times

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minutes: return "分钟"
        case .times: return "遍"
        }
    }
}

enum HabitFrequency: String, CaseIterable, Codable, Identifiable {
    case daily
    case weekdays
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "每天"
        case .weekdays: return "工作日"
        case .weekly: return "每周"
        }
    }
}

struct FocusTask: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var estimate: Int
    var completedSessions: Int = 0
    var isDone: Bool = false
    var priority: TaskPriority = .medium
    var plan: TaskPlan? = .today
    var kind: FocusItemKind?
    var timingStyle: FocusTimingStyle?
    var customDurationSeconds: Int?
    var targetAmount: Int?
    var targetUnit: FocusGoalUnit?
    var habitFrequency: HabitFrequency?
    var deadline: Date?
    var createdAt: Date = Date()
}

struct SessionRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var taskID: UUID?
    var taskTitle: String
    var mode: FocusMode
    var startedAt: Date
    var endedAt: Date
    var seconds: Int
}

struct PracticeEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var taskID: UUID
    var amount: Int
    var unit: FocusGoalUnit
    var recordedAt: Date = Date()
}

struct PracticeSummary: Identifiable, Equatable {
    var id: UUID
    var title: String
    var kind: FocusItemKind
    var unit: FocusGoalUnit
    var today: Int
    var week: Int
    var month: Int
    var year: Int
    var total: Int

    var unitTitle: String { unit.title }
}

private struct AppSnapshot: Codable {
    var tasks: [FocusTask]
    var sessions: [SessionRecord]
    var selectedTaskID: UUID?
    var focusSeconds: Int
    var shortBreakSeconds: Int
    var longBreakSeconds: Int
    var longBreakAfter: Int
    var autoStartBreaks: Bool
    var autoStartFocus: Bool
    var playFinishSound: Bool
    var focusCycleCount: Int
    var practiceEntries: [PracticeEntry]?
}

private struct InspirationDatabase: Decodable {
    struct Record: Decodable {
        let text: String
    }

    let records: [Record]
}

@MainActor
final class FocusStore: ObservableObject {
    @Published var tasks: [FocusTask] = [] { didSet { saveSnapshot() } }
    @Published var sessions: [SessionRecord] = [] { didSet { saveSnapshot() } }
    @Published var practiceEntries: [PracticeEntry] = [] { didSet { saveSnapshot() } }
    @Published var selectedTaskID: UUID? { didSet { saveSnapshot() } }

    @Published var selectedMode: FocusMode = .focus {
        didSet {
            if !isRunning {
                remainingSeconds = duration(for: selectedMode)
            }
        }
    }

    @Published var remainingSeconds: Int = FocusMode.focus.defaultSeconds
    @Published var isRunning = false

    @Published var focusSeconds: Int = FocusMode.focus.defaultSeconds {
        didSet {
            syncDurationIfNeeded(for: .focus)
            saveSnapshot()
        }
    }

    @Published var shortBreakSeconds: Int = FocusMode.shortBreak.defaultSeconds {
        didSet {
            syncDurationIfNeeded(for: .shortBreak)
            saveSnapshot()
        }
    }

    @Published var longBreakSeconds: Int = FocusMode.longBreak.defaultSeconds {
        didSet {
            syncDurationIfNeeded(for: .longBreak)
            saveSnapshot()
        }
    }

    @Published var longBreakAfter: Int = 4 {
        didSet {
            saveSnapshot()
        }
    }

    @Published var autoStartBreaks = false { didSet { saveSnapshot() } }
    @Published var autoStartFocus = false { didSet { saveSnapshot() } }
    @Published var playFinishSound = true { didSet { saveSnapshot() } }
    @Published var focusCycleCount = 0 { didSet { saveSnapshot() } }
    @Published var currentInspirationText: String?

    private let defaultsKey = "tomatoReminder.snapshot.v1"
    private var timer: Timer?
    private var intervalStartedAt: Date?
    private var lastTickAt: Date?
    private var isRestoring = false
    private var inspirationTexts: [String] = []

    init() {
        restoreSnapshot()

        if tasks.isEmpty {
            tasks = [
                FocusTask(title: "整理今天最重要的一件事", estimate: 2, priority: .high),
                FocusTask(title: "读书或课程笔记", estimate: 1, priority: .medium),
                FocusTask(title: "邮件与零碎事务", estimate: 1, priority: .low)
            ]
        }

        remainingSeconds = duration(for: selectedMode)
        inspirationTexts = loadInspirationTexts()
        requestNotificationPermission()
    }

    var selectedTask: FocusTask? {
        guard let selectedTaskID else { return nil }
        return tasks.first(where: { $0.id == selectedTaskID })
    }

    var progress: Double {
        let total = max(duration(for: selectedMode), 1)
        return 1.0 - (Double(remainingSeconds) / Double(total))
    }

    var menuBarTitle: String {
        remainingSeconds.timerText
    }

    var menuBarSystemImage: String {
        isRunning ? "timer.circle.fill" : "timer"
    }

    var todayFocusSeconds: Int {
        sessions
            .filter { Calendar.current.isDateInToday($0.endedAt) && $0.mode == .focus }
            .reduce(0) { $0 + $1.seconds }
    }

    var todayFocusSessions: Int {
        sessions.filter { Calendar.current.isDateInToday($0.endedAt) && $0.mode == .focus }.count
    }

    var todayCompletedTasks: Int {
        tasks.filter(\.isDone).count
    }

    var activeTasks: [FocusTask] {
        tasks.filter { !$0.isDone }
    }

    func taskPlan(for task: FocusTask) -> TaskPlan {
        task.plan ?? .today
    }

    func filteredTasks(for view: PlanView, searchText: String) -> [FocusTask] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseTasks = tasks.filter { task in
            switch view {
            case .today:
                return !task.isDone && taskPlan(for: task) == .today
            case .tomorrow:
                return !task.isDone && taskPlan(for: task) == .tomorrow
            case .thisWeek:
                return !task.isDone && taskPlan(for: task) == .thisWeek
            case .planned:
                return !task.isDone
            case .completed:
                return task.isDone
            case .all:
                return !task.isDone
            case .practiceStats:
                return false
            }
        }

        guard !trimmedSearch.isEmpty else { return baseTasks }
        return baseTasks.filter { $0.title.localizedCaseInsensitiveContains(trimmedSearch) }
    }

    func taskCount(for view: PlanView) -> Int {
        if view == .practiceStats {
            return practiceSummaries(searchText: "").count
        }

        return filteredTasks(for: view, searchText: "").count
    }

    func estimatedSeconds(for view: PlanView) -> Int {
        if view == .practiceStats {
            return practiceSummaries(searchText: "").reduce(0) { $0 + $1.today * 60 }
        }

        return filteredTasks(for: view, searchText: "").reduce(0) { total, task in
            let remainingSessions = max(task.estimate - task.completedSessions, 0)
            return total + remainingSessions * durationSeconds(for: task)
        }
    }

    func duration(for mode: FocusMode) -> Int {
        switch mode {
        case .focus:
            if let customDurationSeconds = selectedTask?.customDurationSeconds {
                return clampedDuration(customDurationSeconds)
            }
            return focusSeconds
        case .shortBreak: return shortBreakSeconds
        case .longBreak: return longBreakSeconds
        }
    }

    func toggleTimer() {
        isRunning ? pauseTimer() : startTimer()
    }

    func startTimer() {
        guard !isRunning else { return }
        let isStartingNewInterval = intervalStartedAt == nil

        if selectedMode == .focus, selectedTaskID == nil {
            selectedTaskID = activeTasks.first?.id
        }

        if selectedMode == .focus, isStartingNewInterval {
            currentInspirationText = inspirationTexts.randomElement()
        }

        intervalStartedAt = intervalStartedAt ?? Date()
        lastTickAt = Date()
        isRunning = true

        timer?.invalidate()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        lastTickAt = nil
    }

    func resetTimer() {
        pauseTimer()
        remainingSeconds = duration(for: selectedMode)
        intervalStartedAt = nil
        if selectedMode == .focus {
            currentInspirationText = nil
        }
    }

    func switchMode(_ mode: FocusMode) {
        selectedMode = mode
        resetTimer()
    }

    func itemKind(for task: FocusTask) -> FocusItemKind {
        task.kind ?? .pomodoro
    }

    func timingStyle(for task: FocusTask) -> FocusTimingStyle {
        task.timingStyle ?? .countdown
    }

    func durationSeconds(for task: FocusTask) -> Int {
        clampedDuration(task.customDurationSeconds ?? focusSeconds)
    }

    func taskSummary(for task: FocusTask) -> String {
        let timingStyle = timingStyle(for: task)
        let minutes = durationSeconds(for: task) / 60

        switch itemKind(for: task) {
        case .pomodoro:
            return "\(timingStyle.title) · \(minutes) 分钟"
        case .habit:
            let frequency = task.habitFrequency?.title ?? HabitFrequency.daily.title
            let amount = task.targetAmount ?? 1
            let unit = task.targetUnit?.title ?? FocusGoalUnit.times.title
            return "\(timingStyle.title)-习惯 · \(frequency) \(amount)\(unit)"
        case .goal:
            let amount = task.targetAmount ?? max(task.estimate, 1)
            let unit = task.targetUnit?.title ?? FocusGoalUnit.times.title
            let completed: Int
            if task.targetUnit == .minutes {
                completed = task.completedSessions * durationSeconds(for: task) / 60
            } else {
                completed = task.completedSessions
            }
            return "\(timingStyle.title)-目标 · \(completed)/\(amount)\(unit)"
        }
    }

    func practiceSummaries(searchText: String) -> [PracticeSummary] {
        let calendar = Calendar.current
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let sourceTasks = tasks.filter { task in
            !task.isDone || sessions.contains(where: { $0.taskID == task.id })
        }
        .filter { task in
            trimmedSearch.isEmpty || task.title.localizedCaseInsensitiveContains(trimmedSearch)
        }

        return sourceTasks.map { task in
            let taskSessions = sessions.filter { $0.taskID == task.id && $0.mode == .focus }
            let unit = task.targetUnit ?? (itemKind(for: task) == .pomodoro ? .times : .minutes)
            let taskEntries = practiceEntries.filter { $0.taskID == task.id }

            func amount(for sessions: [SessionRecord]) -> Int {
                switch unit {
                case .minutes:
                    return sessions.reduce(0) { $0 + max($1.seconds / 60, 1) }
                case .times:
                    return sessions.count
                }
            }

            func entryAmount(for entries: [PracticeEntry]) -> Int {
                entries.reduce(0) { total, entry in
                    total + max(entry.amount, 0)
                }
            }

            let todaySessions = taskSessions.filter { calendar.isDateInToday($0.endedAt) }
            let weekSessions = taskSessions.filter { calendar.isDate($0.endedAt, equalTo: Date(), toGranularity: .weekOfYear) }
            let monthSessions = taskSessions.filter { calendar.isDate($0.endedAt, equalTo: Date(), toGranularity: .month) }
            let yearSessions = taskSessions.filter { calendar.isDate($0.endedAt, equalTo: Date(), toGranularity: .year) }
            let todayEntries = taskEntries.filter { calendar.isDateInToday($0.recordedAt) }
            let weekEntries = taskEntries.filter { calendar.isDate($0.recordedAt, equalTo: Date(), toGranularity: .weekOfYear) }
            let monthEntries = taskEntries.filter { calendar.isDate($0.recordedAt, equalTo: Date(), toGranularity: .month) }
            let yearEntries = taskEntries.filter { calendar.isDate($0.recordedAt, equalTo: Date(), toGranularity: .year) }

            return PracticeSummary(
                id: task.id,
                title: task.title,
                kind: itemKind(for: task),
                unit: unit,
                today: amount(for: todaySessions) + entryAmount(for: todayEntries),
                week: amount(for: weekSessions) + entryAmount(for: weekEntries),
                month: amount(for: monthSessions) + entryAmount(for: monthEntries),
                year: amount(for: yearSessions) + entryAmount(for: yearEntries),
                total: amount(for: taskSessions) + entryAmount(for: taskEntries)
            )
        }
        .sorted {
            if $0.today == $1.today {
                return $0.total > $1.total
            }
            return $0.today > $1.today
        }
    }

    func addPractice(title: String, unit: FocusGoalUnit) {
        addTask(
            title: title,
            estimate: 1,
            priority: .medium,
            plan: .today,
            kind: .habit,
            timingStyle: .none,
            durationSeconds: focusSeconds,
            targetAmount: 1,
            targetUnit: unit,
            habitFrequency: .daily
        )
    }

    func addPracticeEntry(taskID: UUID, amount: Int) {
        guard let task = tasks.first(where: { $0.id == taskID }) else { return }
        let entry = PracticeEntry(
            taskID: taskID,
            amount: max(amount, 1),
            unit: task.targetUnit ?? .times
        )
        practiceEntries.append(entry)
    }

    func renamePractice(taskID: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = tasks.firstIndex(where: { $0.id == taskID })
        else { return }

        tasks[index].title = trimmed
    }

    func deletePractice(taskID: UUID) {
        guard tasks.contains(where: { $0.id == taskID }) else { return }

        tasks.removeAll { $0.id == taskID }
        practiceEntries.removeAll { $0.taskID == taskID }

        if selectedTaskID == taskID {
            selectedTaskID = activeTasks.first?.id
        }

        if selectedMode == .focus, !isRunning {
            remainingSeconds = duration(for: .focus)
        }
    }

    func addTask(
        title: String,
        estimate: Int,
        priority: TaskPriority,
        plan: TaskPlan = .today,
        kind: FocusItemKind = .pomodoro,
        timingStyle: FocusTimingStyle = .countdown,
        durationSeconds: Int? = nil,
        targetAmount: Int? = nil,
        targetUnit: FocusGoalUnit? = nil,
        habitFrequency: HabitFrequency? = nil,
        deadline: Date? = nil
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var task = FocusTask(title: trimmed, estimate: max(1, estimate), priority: priority, plan: plan)
        task.kind = kind
        task.timingStyle = timingStyle
        task.customDurationSeconds = durationSeconds.map(clampedDuration)
        task.targetAmount = targetAmount.map { max(1, $0) }
        task.targetUnit = targetUnit
        task.habitFrequency = habitFrequency
        task.deadline = deadline
        tasks.insert(task, at: 0)
        selectedTaskID = task.id

        if selectedMode == .focus, !isRunning {
            remainingSeconds = duration(for: .focus)
        }
    }

    func deleteTasks(at offsets: IndexSet) {
        let ids = offsets.map { tasks[$0].id }
        tasks.remove(atOffsets: offsets)
        if let selectedTaskID, ids.contains(selectedTaskID) {
            self.selectedTaskID = activeTasks.first?.id
        }
    }

    func selectTask(_ task: FocusTask) {
        selectedTaskID = task.id
        if selectedMode == .focus, !isRunning {
            remainingSeconds = duration(for: .focus)
        }
    }

    func toggleTaskDone(_ task: FocusTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()

        if tasks[index].isDone, selectedTaskID == task.id {
            selectedTaskID = activeTasks.first?.id
        }
    }

    func incrementEstimate(for task: FocusTask, by delta: Int) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].estimate = max(1, min(12, tasks[index].estimate + delta))
    }

    func moveTask(_ task: FocusTask, to plan: TaskPlan) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].plan = plan
    }

    func markSelectedTaskDone() {
        guard let selectedTask else { return }
        toggleTaskDone(selectedTask)
    }

    func finishCurrentIntervalNow() {
        if isRunning {
            completeCurrentInterval()
        } else {
            markSelectedTaskDone()
        }
    }

    func clearCompletedTasks() {
        tasks.removeAll(where: \.isDone)
        if let selectedTaskID, !tasks.contains(where: { $0.id == selectedTaskID }) {
            self.selectedTaskID = activeTasks.first?.id
        }
    }

    func clearTodaySessions() {
        sessions.removeAll { Calendar.current.isDateInToday($0.endedAt) }
        focusCycleCount = 0
    }

    func setDuration(for mode: FocusMode, minutes: Int) {
        let seconds = clampedDuration(minutes * 60)

        switch mode {
        case .focus:
            focusSeconds = seconds
        case .shortBreak:
            shortBreakSeconds = seconds
        case .longBreak:
            longBreakSeconds = seconds
        }
    }

    func setLongBreakAfter(_ count: Int) {
        longBreakAfter = min(max(count, 2), 8)
    }

    private func tick() {
        guard isRunning else { return }

        let now = Date()
        let elapsed = max(1, Int(now.timeIntervalSince(lastTickAt ?? now)))
        lastTickAt = now
        remainingSeconds = max(remainingSeconds - elapsed, 0)

        if remainingSeconds == 0 {
            completeCurrentInterval()
        }
    }

    private func completeCurrentInterval() {
        let completedMode = selectedMode
        let endDate = Date()
        let startedAt = intervalStartedAt ?? endDate.addingTimeInterval(TimeInterval(-duration(for: completedMode)))
        let completedSeconds = max(duration(for: completedMode) - remainingSeconds, 1)
        let taskTitle = selectedTask?.title ?? "自由专注"
        let taskID = selectedTask?.id

        pauseTimer()
        sessions.append(SessionRecord(
            taskID: taskID,
            taskTitle: taskTitle,
            mode: completedMode,
            startedAt: startedAt,
            endedAt: endDate,
            seconds: completedSeconds
        ))

        if completedMode == .focus {
            completeFocusSession(for: taskID)
        }

        notifyCompletion(for: completedMode)
        advanceMode(after: completedMode)
    }

    private func completeFocusSession(for taskID: UUID?) {
        focusCycleCount += 1

        guard let taskID, let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].completedSessions += 1

        if itemKind(for: tasks[index]) != .habit, tasks[index].completedSessions >= tasks[index].estimate {
            tasks[index].isDone = true
            selectedTaskID = activeTasks.first?.id
        }
    }

    private func advanceMode(after completedMode: FocusMode) {
        intervalStartedAt = nil

        switch completedMode {
        case .focus:
            selectedMode = focusCycleCount % longBreakAfter == 0 ? .longBreak : .shortBreak
            remainingSeconds = duration(for: selectedMode)
            if autoStartBreaks {
                startTimer()
            }
        case .shortBreak, .longBreak:
            selectedMode = .focus
            remainingSeconds = duration(for: .focus)
            currentInspirationText = nil
            if autoStartFocus {
                startTimer()
            }
        }
    }

    private func notifyCompletion(for mode: FocusMode) {
        if playFinishSound {
            NSSound(named: NSSound.Name("Glass"))?.play()
        }

        let content = UNMutableNotificationContent()
        content.title = mode == .focus ? "一个番茄完成" : "休息结束"
        content.body = mode == .focus ? "保存一下进度，然后进入休息。" : "回到当前任务，开始下一轮。"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func clampedDuration(_ seconds: Int) -> Int {
        min(max(seconds, 60), 120 * 60)
    }

    private func syncDurationIfNeeded(for mode: FocusMode) {
        if selectedMode == mode, !isRunning {
            remainingSeconds = duration(for: mode)
        }
    }

    private func restoreSnapshot() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let snapshot = try? JSONDecoder().decode(AppSnapshot.self, from: data)
        else { return }

        isRestoring = true
        tasks = snapshot.tasks
        sessions = snapshot.sessions
        practiceEntries = snapshot.practiceEntries ?? []
        selectedTaskID = snapshot.selectedTaskID
        focusSeconds = clampedDuration(snapshot.focusSeconds)
        shortBreakSeconds = clampedDuration(snapshot.shortBreakSeconds)
        longBreakSeconds = clampedDuration(snapshot.longBreakSeconds)
        longBreakAfter = min(max(snapshot.longBreakAfter, 2), 8)
        autoStartBreaks = snapshot.autoStartBreaks
        autoStartFocus = snapshot.autoStartFocus
        playFinishSound = snapshot.playFinishSound
        focusCycleCount = snapshot.focusCycleCount
        isRestoring = false
    }

    private func saveSnapshot() {
        guard !isRestoring else { return }

        let snapshot = AppSnapshot(
            tasks: tasks,
            sessions: sessions,
            selectedTaskID: selectedTaskID,
            focusSeconds: focusSeconds,
            shortBreakSeconds: shortBreakSeconds,
            longBreakSeconds: longBreakSeconds,
            longBreakAfter: longBreakAfter,
            autoStartBreaks: autoStartBreaks,
            autoStartFocus: autoStartFocus,
            playFinishSound: playFinishSound,
            focusCycleCount: focusCycleCount,
            practiceEntries: practiceEntries
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func loadInspirationTexts() -> [String] {
        let urls = [
            Bundle.main.resourceURL?.appendingPathComponent("data/qishi_ocr.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("data/qishi_ocr.json")
        ].compactMap { $0 }

        guard
            let url = urls.first(where: { FileManager.default.fileExists(atPath: $0.path) }),
            let data = try? Data(contentsOf: url),
            let database = try? JSONDecoder().decode(InspirationDatabase.self, from: data)
        else { return [] }

        return database.records
            .compactMap { Self.inspirationCandidate(from: $0.text) }
            .uniqued()
    }

    private static func inspirationCandidate(from text: String) -> String? {
        let ignoredExactLines: Set<String> = [
            "打开",
            "我治好您，您治好世界",
            "我治好您 您治好世界",
            "日中一坐",
            "专注中",
            "休息中",
            "点击填写本次专注心得",
            "结果生成中…"
        ]

        let ignoredFragments = [
            "我治好您",
            "您治好世界",
            "五根本气",
            "根本气",
            "习惯"
        ]

        let lines = text
            .components(separatedBy: .newlines)
            .map { Self.cleanedInspirationLine($0) }
            .filter { line in
                guard !ignoredExactLines.contains(line) else { return false }
                guard !ignoredFragments.contains(where: { line.contains($0) }) else { return false }
                guard !line.allSatisfy({ $0.isNumber || $0 == ":" || $0 == " " }) else { return false }
                guard line.range(of: "\\p{Han}", options: .regularExpression) != nil else { return false }
                if line.count >= 3 { return true }
                return line.rangeOfCharacter(from: CharacterSet(charactersIn: "的一是在不有中人了为和以到始向上子己自心力生")) != nil
            }

        let quote = lines.joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard quote.count >= 12 else { return nil }
        return quote
    }

    private static func cleanedInspirationLine(_ line: String) -> String {
        line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: #"^\d{1,2}[:：]\d{2}\s*[-—–~·•|丨:：>》）\]\)]*\s*"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"[-—–~·•|丨:：>》）\]\)]*\s*今日\s*\d+\s*/\s*\d+\s*[次遍]\s*$"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"(?<=\p{Han})[.．](?=\p{Han})"#,
                with: "，",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Int {
    var timerText: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var hourMinuteText: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60

        if hours == 0 {
            return "\(minutes) 分钟"
        }

        return "\(hours) 小时 \(minutes) 分钟"
    }

    var compactDurationText: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60

        if hours == 0 {
            return "\(minutes)m"
        }

        if minutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(minutes)m"
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
