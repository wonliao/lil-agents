import AppKit

class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class CharacterContentView: NSView {
    weak var character: WalkerCharacter?
    private var dragStartPoint: NSPoint?
    private var windowStartOrigin: NSPoint?
    private var isDragging = false
    private var isRepositionEnabled: Bool { WalkerCharacter.behavior.repositionEnabled }
    private let dragThreshold: CGFloat = 5

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        guard bounds.contains(localPoint) else { return nil }
        // Keep hit-testing simple and robust so drag gestures are always received.
        // The old per-pixel alpha sampling can miss events on some systems.
        return self
    }

    override func mouseDown(with event: NSEvent) {
        if !isRepositionEnabled {
            resetDragState()
            return
        }
        dragStartPoint = NSEvent.mouseLocation
        windowStartOrigin = window?.frame.origin
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard isRepositionEnabled else { return }
        guard let startPoint = dragStartPoint, let startOrigin = windowStartOrigin else { return }
        let current = NSEvent.mouseLocation
        let dx = current.x - startPoint.x
        let dy = current.y - startPoint.y

        if !isDragging && (abs(dx) > dragThreshold || abs(dy) > dragThreshold) {
            isDragging = true
            character?.startDrag()
        }

        if isDragging {
            // Keep the character anchored vertically to the dock line;
            // allow repositioning only along X.
            window?.setFrameOrigin(NSPoint(x: startOrigin.x + dx, y: startOrigin.y))
            character?.trackDragVelocity()
        }
    }

    override func mouseUp(with event: NSEvent) {
        if !isRepositionEnabled {
            character?.handleClick()
            resetDragState()
            return
        }
        if !isDragging {
            character?.handleClick()
        } else {
            character?.endDrag()
        }
        resetDragState()
    }

    private func resetDragState() {
        isDragging = false
        dragStartPoint = nil
        windowStartOrigin = nil
    }
}
