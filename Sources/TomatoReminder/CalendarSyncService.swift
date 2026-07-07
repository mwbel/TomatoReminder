import EventKit
import Foundation

enum CalendarSyncError: LocalizedError {
    case accessDenied
    case calendarUnavailable
    case eventIdentifierMissing
    case unknownAuthorization

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "没有日历访问权限。请在系统设置中允许 Tomato Reminder 访问日历。"
        case .calendarUnavailable:
            return "没有找到可写入的日历账户。请先在系统日历中启用一个可写日历。"
        case .eventIdentifierMissing:
            return "日历事件已创建，但系统没有返回事件 ID。"
        case .unknownAuthorization:
            return "当前日历权限状态暂不支持同步。"
        }
    }
}

struct CalendarSyncResult {
    let eventIdentifier: String
    let calendarTitle: String
    let scheduledDate: Date
}

@MainActor
final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let eventStore = EKEventStore()
    private let calendarTitle = "Tomato Reminder"

    private init() {}

    func syncTask(
        _ task: FocusTask,
        scheduledOn date: Date,
        planTitle: String,
        summary: String
    ) async throws -> CalendarSyncResult {
        try await ensureCalendarAccess()

        let targetCalendar = try writableCalendar()
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate.addingTimeInterval(86_400)
        let event = existingEvent(for: task.calendarEventID) ?? EKEvent(eventStore: eventStore)

        event.calendar = targetCalendar
        event.title = task.title
        event.isAllDay = true
        event.startDate = startDate
        event.endDate = endDate
        event.notes = [
            "由 Tomato Reminder 手动同步。",
            "计划：\(planTitle)",
            "类型：\(task.kind?.title ?? FocusItemKind.pomodoro.title)",
            "摘要：\(summary)",
            "说明：这里同步的是任务计划，不会写入番茄钟专注记录。"
        ].joined(separator: "\n")

        try eventStore.save(event, span: .thisEvent, commit: true)

        guard let eventIdentifier = event.eventIdentifier else {
            throw CalendarSyncError.eventIdentifierMissing
        }

        return CalendarSyncResult(
            eventIdentifier: eventIdentifier,
            calendarTitle: targetCalendar.title,
            scheduledDate: startDate
        )
    }

    private func ensureCalendarAccess() async throws {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            return
        case .notDetermined:
            let granted = try await eventStore.requestFullAccessToEvents()
            if !granted {
                throw CalendarSyncError.accessDenied
            }
        case .denied, .restricted, .writeOnly:
            throw CalendarSyncError.accessDenied
        @unknown default:
            throw CalendarSyncError.unknownAuthorization
        }
    }

    private func writableCalendar() throws -> EKCalendar {
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents,
           defaultCalendar.allowsContentModifications {
            return defaultCalendar
        }

        if let calendar = eventStore.calendars(for: .event).first(where: {
            $0.title == calendarTitle && $0.allowsContentModifications
        }) {
            return calendar
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarTitle

        if let source = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = source
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        } else if let source = eventStore.sources.first {
            calendar.source = source
        } else {
            throw CalendarSyncError.calendarUnavailable
        }

        try eventStore.saveCalendar(calendar, commit: true)
        return calendar
    }

    private func existingEvent(for eventIdentifier: String?) -> EKEvent? {
        guard let eventIdentifier else { return nil }
        return eventStore.event(withIdentifier: eventIdentifier)
    }
}
