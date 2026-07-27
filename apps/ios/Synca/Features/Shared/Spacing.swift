import CoreGraphics

/// See docs/design/ui-system.md § Spacing / Corner Radius.
enum Spacing {
    static let space1: CGFloat = 3
    static let space2: CGFloat = 6
    static let space3: CGFloat = 8
    static let space4: CGFloat = 11
    static let space6: CGFloat = 17
    static let space8: CGFloat = 22
}

enum Radius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 14
    static let full: CGFloat = 999
}
