import AppKit
import Foundation

enum AppFontSize {
    private static let systemReferenceBodySize: CGFloat = 13

    static var scale: CGFloat {
        let preferredBodySize = NSFont.preferredFont(forTextStyle: .body).pointSize
        return min(max(preferredBodySize / systemReferenceBodySize, 1.08), 1.45)
    }

    static func scaled(_ size: CGFloat) -> CGFloat {
        size * scale
    }
}
