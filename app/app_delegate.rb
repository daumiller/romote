class AppDelegate
  def applicationDidFinishLaunching(_notification)
    build_menu
    load_window
  end

  def applicationShouldTerminateAfterLastWindowClosed(_application)
    true
  end

  def load_window
    @window_controller = RomoteWindowController.alloc.initWithWindowNibName('RomoteWindow')
    @window_controller.window.makeKeyAndOrderFront(self)
  end
end
