import AppKit
import Foundation

enum AppFontSize {
    private static let baseBodySize: CGFloat = 13

    static var scale: CGFloat {
        let preferredBodySize = NSFont.preferredFont(forTextStyle: .body).pointSize
        return min(max(preferredBodySize / baseBodySize, 0.85), 1.8)
    }

    static func scaled(_ size: CGFloat) -> CGFloat {
        size * scale
    }
}
