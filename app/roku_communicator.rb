class RokuCommunicator < NSObject

  DISCOVERY_HOST   = '239.255.255.250'
  DISCOVERY_PORT   = 1900
  DISCOVERY_PACKET = "M-SEARCH * HTTP/1.1\n"                       \
                     "Host: #{DISCOVERY_HOST}:#{DISCOVERY_PORT}\n" \
                     "Man: \"ssdp:discover\"\n"                    \
                     "ST: roku:ecp\n\n"

  attr_accessor :roku_service, :roku_id, :last_error

  def initialize(delegate)
    @state    = :idle
    @delegate = delegate
    self.roku_service = nil
    self.roku_id      = nil
    self.last_error   = nil
  end

  # this is mainly to validate 'manual' user entry, but caller can rely on it too.
  # we'll allow:
  #   i) full service description : http://192.168.1.128:8060
  #  ii) ip and port only         :        192.168.1.128:8060
  # iii) ip only                  :        192.168.1.128
  def roku_service=(service)
    if service.nil?
      @roku_service = nil
      return
    end

    if service.match /HTTP:\/\//i
      fail "Bad Service Format '#{service}'." unless service.match /^HTTP:\/\/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+\/?$/i
      service += '/' unless service.end_with? '/'
    elsif service.match /:[0-9]+$/
      fail "Bad Service Format '#{service}'." unless service.match /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$/
      service = "http://#{service}/"
    else
      fail "Bad Service Format '#{service}'." unless service.match /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/
      service = "http://#{service}:8060/"
    end
    @roku_service = service
  end

  # search for local Roku devices with SSDP
  # if not found before timeout (in floating seconds) expires, prompt to Retry/Manually-Enter/Exit
  def search(timeout)
    fail "RokuCommunicator.search_begin called during invalid state: #{@state}." if @state != :idle

    @timeout = timeout
    @socket  =  GCDAsyncUdpSocket.alloc.initWithDelegateOnMainQueue self

    self.last_error = nil
    error_ptr = Pointer.new :object

    unless @socket.bindToPort 0, error: error_ptr
      error = error_ptr[0]
      self.last_error = "Error creating UDP listener (during bind)\n#{error}"
      @delegate.roku_device_found
      return
    end

    unless @socket.beginReceiving error_ptr
      @socket.close
      error = error_ptr[0]
      self.last_error = "Error creating UDP listener (during begin)\n#{error}"
      @delegate.roku_device_found
      return
    end

    @state = :searching
    data = DISCOVERY_PACKET.dataUsingEncoding NSUTF8StringEncoding
    @socket.sendData data, toHost: DISCOVERY_HOST, port: DISCOVERY_PORT, withTimeout: -1, tag: 0
    performSelector 'search_timeout:', withObject: nil, afterDelay: @timeout
  end

  # we'll get called whether or not a timeout has occured
  def search_timeout(_object)
    return if roku_service
    begin
      search_stop
    rescue
      # we could possibly run into a timing issue here.
      # rescue search_stop errors if it happened to be working while we were.
      @socket.close
      @state = :idle
    end
    return if roku_service

    # show our Retry/Manul/Exit prompt
    first_manual_attempt = true
    while true
      alert = NSAlert.alertWithMessageText 'No Roku device found.',
                            defaultButton: 'Retry Search',
                          alternateButton: 'Enter Manually',
                              otherButton: 'Exit',
                informativeTextWithFormat: (first_manual_attempt ? 'Roku IP address:' : 'The address entered was not correctly formatted.')
      roku_service = NSTextField.alloc.initWithFrame NSMakeRect(0, 0, 200, 24)
      roku_service.setStringValue:'192.168.'
      alert.setAccessoryView roku_service

      result = alert.runModal
      if result == NSAlertDefaultReturn
        search @timeout
        return
      elsif result == NSAlertAlternateReturn
        roku_service.validateEditing
        begin
          self.roku_service = roku_service.stringValue
        rescue
          # invalid manual entry
          first_manual_attempt = false
        end
        if first_manual_attempt
          # valid manual entry
          @delegate.roku_device_found
          return
        end
      else
        NSApp.terminate self
        return
      end
    end
  end

  # stop listening socket when a device is found || timeout reached
  def search_stop
    fail "RokuCommunicator.search_stop called during invalid state: #{@state}." if @state != :searching
    @socket.close
    @state = :idle
  end

  def udpSocket(socket, didReceiveData: data, fromAddress: address, withFilterContext: _filter)
    return if roku_service

    message = NSString.alloc.initWithData data, encoding: NSUTF8StringEncoding
    return unless message

    lines = message.gsub("\r\n", "\n").split "\n"
    return unless lines.grep(/HTTP\/[0-9](\.[0-9]) 200 OK/).count == 1
    return unless lines.grep(/ST: ROKU:ECP/i).count == 1

    service_line = lines.grep /LOCATION: HTTP:\/\//i
    if service_line.count == 1
      service_line = service_line[0]
      found_service = service_line.match /HTTP:\/\/.+$/i
      self.roku_service = found_service[0] if found_service && found_service.length == 1
    end
    return unless roku_service

    id_line = lines.grep /USN: UUID:ROKU:ECP:*/i
    if id_line.count == 1
      id_line = id_line[0]
      found_id = id_line.match /[^:]+$/
      self.roku_id = found_id[0] if found_id && found_id.length == 1
    end

    @socket.close
    @state = :idle
    @delegate.roku_device_found
  end

  def channel_list
    channel_list_retrieved = Proc.new { |response, error|
      unless error.nil?
        self.last_error = error
        @delegate.roku_channels_retrieved {}
        return
      end
      # parse into channels
      puts "Channel List: #{response}"
      @delegate.roku_channels_retrieved({ 'Netflix' => 2, 'Plex' => 33539 })
    }
    FragileHttpClient.get "#{roku_service}query/apps", channel_list_retrieved
  end

end
