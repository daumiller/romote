class RomoteWindowController < NSWindowController
  extend IB

  outlet :btn_back      , NSButton
  outlet :btn_home      , NSButton
  outlet :btn_up        , NSButton
  outlet :btn_down      , NSButton
  outlet :btn_left      , NSButton
  outlet :btn_right     , NSButton
  outlet :btn_select    , NSButton
  outlet :btn_replay    , NSButton
  outlet :btn_info      , NSButton
  outlet :btn_reverse   , NSButton
  outlet :btn_forward   , NSButton
  outlet :btn_play      , NSButton
  outlet :lst_channel   , NSPopUpButton
  outlet :txt_keyboard  , NSTextField
  outlet :img_background, NSImageView


  def windowDidLoad
    @lst_channel.removeAllItems
    # attempt to find roku
    # prompt for IP if not found (cancel exits)
  end

  def non_text_input
    self.window.makeFirstResponder nil
    @txt_keyboard.setStringValue ''
  end

  def press_back(sender)
    non_text_input
  end
  def press_home(sender)
    non_text_input
  end
  def press_up(sender)
    non_text_input
  end
  def press_down(sender)
    non_text_input
  end
  def press_left(sender)
    non_text_input
  end
  def press_right(sender)
    non_text_input
  end
  def press_select(sender)
    non_text_input
    alert = NSAlert.new
    alert.messageText = "Select"
    alert.runModal
  end
  def press_replay(sender)
    non_text_input
  end
  def press_info(sender)
    non_text_input
  end
  def press_reverse(sender)
    non_text_input
  end
  def press_play(sender)
    non_text_input
  end
  def press_forward(sender)
    non_text_input
  end

  def select_channel(sender)
    non_text_input
  end

  def enter_text(sender)
  end

end
