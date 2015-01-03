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
    @roku_service = nil
    @discovery = RokuDiscovery.new self
    @discovery.search 3.0
  end

  def roku_device_found
    if @discovery.last_error
      alert = NSAlert.new
      alert.messageText = "Networking Error: #{@discovery.last_error}."
      alert.runModal
      NSApp.terminate self
    end

    @roku_service = @discovery.roku_service
    @discovery = nil
    @http = AFMotion::Client.build(@roku_service) do
      header 'Connection', 'close'
    end

    get_channels
  end

  def get_channels
    AFMotion::XML.get("#{@roku_service}query/apps") do |result|
      if result.failure?
        alert = NSAlert.alertWithMessageText 'Failed to retrieve channel list from the Roku.',
                              defaultButton: 'Retry',
                            alternateButton: 'Continue',
                                otherButton: nil,
                  informativeTextWithFormat: 'You can continue anyway; but direct channel selection will not be available.'
        result = alert.runModal
        get_channels if result NSAlertDefaultReturn
        return
      else
        result.object.delegate = XmlChannelParser.new
        result.object.parse
        @channels = result.object.delegate.channels
        @lst_channel.removeAllItems
        @channels.each do |channel, _id|
          @lst_channel.addItemWithTitle channel
        end
      end
    end
  end

  def non_text_input
    window.makeFirstResponder nil
    @txt_keyboard.setStringValue ''
  end

  def keypress(key)
    non_text_input
    return if @roku_service.nil?
    @http.post "keypress/#{key}"
  end

  def press_back   (_sender) ; keypress 'Back'          ; end
  def press_home   (_sender) ; keypress 'Home'          ; end
  def press_up     (_sender) ; keypress 'Up'            ; end
  def press_down   (_sender) ; keypress 'Down'          ; end
  def press_left   (_sender) ; keypress 'Left'          ; end
  def press_right  (_sender) ; keypress 'Right'         ; end
  def press_select (_sender) ; keypress 'Select'        ; end
  def press_replay (_sender) ; keypress 'InstantReplay' ; end
  def press_info   (_sender) ; keypress 'Info'          ; end
  def press_reverse(_sender) ; keypress 'Rev'           ; end
  def press_play   (_sender) ; keypress 'Play'          ; end
  def press_forward(_sender) ; keypress 'Fwd'           ; end


  def select_channel(sender)
    non_text_input
    channel_name = sender.titleOfSelectedItem
    channel_id   = @channels[channel_name]
    @http.post "launch/#{channel_id}"
  end

  def enter_text(sender)
  end

end
