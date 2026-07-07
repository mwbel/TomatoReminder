import AppKit
import Foundation

enum AppFontSize {
    private static let compactReferenceBodySize: CGFloat = 15

    static var scale: CGFloat {
        let preferredBodySize = NSFont.preferredFont(forTextStyle: .body).pointSize
        return min(max(preferredBodySize / compactReferenceBodySize, 0.84), 1.18)
    }

    static func scaled(_ size: CGFloat) -> CGFloat {
        size * scale
    }
}
