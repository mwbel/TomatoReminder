import SwiftUI

@main
struct TomatoReminderApp: App {
    @StateObject private var store = FocusStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 820, minHeight: 520)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button(store.isRunning ? "暂停计时" : "开始计时") {
                    store.toggleTimer()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("重置当前计时") {
                    store.resetTimer()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra {
            MenuBarTimerMenu()
                .environmentObject(store)
        } label: {
            MenuBarTimerBadge(
                seconds: store.remainingSeconds,
                mode: store.selectedMode,
                isRunning: store.isRunning
            )
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct MenuBarTimerBadge: View {
    let seconds: Int
    let mode: FocusMode
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "timer")
                .font(.system(size: AppFontSize.scaled(9), weight: .heavy))
                .symbolRenderingMode(.monochrome)

            Text(seconds.timerText)
                .font(.system(size: AppFontSize.scaled(11), weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
            .foregroundStyle(.white)
            .padding(.leading, 5)
            .padding(.trailing, 6)
            .frame(minWidth: 56, minHeight: 20)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(badgeColor)
            )
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(isRunning ? 0.85 : 0.45))
                    .frame(width: 3, height: 3)
                    .padding(3)
            }
            .accessibilityLabel("番茄钟 \(seconds.timerText)")
    }

    private var badgeColor: Color {
        if !isRunning {
            return Color(hex: 0x8E96A3)
        }

        switch mode {
        case .focus:
            return Color(hex: 0xF05A4F)
        case .shortBreak:
            return Color(hex: 0x2E9E73)
        case .longBreak:
            return Color(hex: 0x3E7CB1)
        }
    }
}

private struct MenuBarTimerMenu: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        VStack {
            Text("\(store.selectedMode.title) \(store.remainingSeconds.timerText)")
                .font(.headline)

            if let task = store.selectedTask {
                Text(task.title)
                    .lineLimit(1)
            } else {
                Text("未选择任务")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button(store.isRunning ? "暂停计时" : "开始计时") {
                store.toggleTimer()
            }
            .keyboardShortcut(.space, modifiers: [])

            Button("重置当前计时") {
                store.resetTimer()
            }
            .keyboardShortcut("r", modifiers: [.command])

            Divider()

            Button("专注") {
                store.switchMode(.focus)
            }

            Button("短休息") {
                store.switchMode(.shortBreak)
            }

            Button("长休息") {
                store.switchMode(.longBreak)
            }
        }
    }
}
