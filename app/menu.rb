class AppDelegate
  def build_menu
    @menu = NSMenu.new

    appName = NSBundle.mainBundle.infoDictionary['CFBundleName']
    add_menu(appName) do
      addItemWithTitle("Hide #{appName}", action: 'hide:', keyEquivalent: 'h')
      item = addItemWithTitle('Hide Others', action: 'hideOtherApplications:', keyEquivalent: 'H')
      item.keyEquivalentModifierMask = NSCommandKeyMask|NSAlternateKeyMask
      addItemWithTitle('Show All', action: 'unhideAllApplications:', keyEquivalent: '')
      addItem(NSMenuItem.separatorItem)
      addItemWithTitle("Quit #{appName}", action: 'terminate:', keyEquivalent: 'q')
    end

    NSApp.windowsMenu = add_menu('Window') do
      addItemWithTitle('Minimize', action: 'performMiniaturize:', keyEquivalent: 'm')
      addItem(NSMenuItem.separatorItem)
      addItemWithTitle('Bring All To Front', action: 'arrangeInFront:', keyEquivalent: '')
    end.menu

    NSApp.helpMenu = add_menu('Help') do
      addItemWithTitle("#{appName} Help", action: 'showHelp:', keyEquivalent: '?')
    end.menu

    NSApp.mainMenu = @menu
  end

  private

  def add_menu(title, &b)
    item = create_menu(title, &b)
    @menu.addItem item
    item
  end

  def create_menu(title, &b)
    menu = NSMenu.alloc.initWithTitle(title)
    menu.instance_eval(&b) if b
    item = NSMenuItem.alloc.initWithTitle(title, action: nil, keyEquivalent: '')
    item.submenu = menu
    item
  end
end
