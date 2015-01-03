class PointerButton < NSButton
  def resetCursorRects
    addCursorRect bounds, cursor: NSCursor.pointingHandCursor
  end
end
