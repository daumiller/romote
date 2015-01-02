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
    @rocomm = RokuCommunicator.new self
    @rocomm.search 3.0
  end

  def roku_device_found
    if @rocomm.last_error
      alert = NSAlert.new
      alert.messageText = "Networking Error: #{@rocomm.last_error}."
      alert.runModal
      NSApp.terminate self
    end

    alert = NSAlert.new
    alert.messageText = "Found Roku Device #{@rocomm.roku_id} at #{@rocomm.roku_service}."
    alert.runModal
  end

  def non_text_input
    window.makeFirstResponder nil
    @txt_keyboard.setStringValue ''
  end

  def press_back(_sender)
    non_text_input
  end

  def press_home(_sender)
    non_text_input
  end

  def press_up(_sender)
    non_text_input
  end

  def press_down(_sender)
    non_text_input
  end

  def press_left(_sender)
    non_text_input
  end

  def press_right(_sender)
    non_text_input
  end

  def press_select(_sender)
    non_text_input
  end

  def press_replay(_sender)
    non_text_input
  end

  def press_info(_sender)
    non_text_input
  end

  def press_reverse(_sender)
    non_text_input
  end

  def press_play(_sender)
    non_text_input
  end

  def press_forward(_sender)
    non_text_input
  end

  def select_channel(sender)
    non_text_input
  end

  def enter_text(sender)
  end

end
