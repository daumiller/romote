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

  def search_timeout(_object)
    begin
      search_stop
    rescue
      @socket.close
      @state = :idle
      # not doing a check-and-return before calling stop,
      # just so we don't have to deal with any timing issues...
    end
    return if roku_service

    # show our Retry/Manul/Exit prompt
    alert = NSAlert.alertWithMessageText 'No Roku device found.',
                          defaultButton: 'Retry Search',
                        alternateButton: 'Enter Manually',
                            otherButton: 'Exit',
              informativeTextWithFormat: 'Roku IP address:'
    roku_service = NSTextField.alloc.initWithFrame NSMakeRect(0, 0, 200, 24)
    roku_service.setStringValue:'192.168.1.'
    alert.setAccessoryView roku_service

    result = alert.runModal
    if result == NSAlertDefaultReturn
      search @timeout
    elsif result == NSAlertAlternateReturn
      roku_service.validateEditing
      self.roku_service = roku_service.stringValue
      @delegate.roku_device_found
    else
      NSApp.terminate self
    end
  end

  def search_stop
    fail "RokuCommunicator.search_stop called during invalid state: #{@state}." if @state != :searching
    @socket.close
    @state = :idle
  end

  def udpSocket(socket, didReceiveData: data, fromAddress: address, withFilterContext: _filter)
    puts 'udpSocket.A'
    return if roku_service

    message = NSString.alloc.initWithData data, encoding: NSUTF8StringEncoding
    puts "udpSocket.B #{message}"
    return unless message

    lines = message.gsub("\r\n", "\n").split "\n"
    return unless lines.grep(/HTTP\/[0-9](\.[0-9]) 200 OK/).count == 1
    puts 'udpSocket.C'
    return unless lines.grep(/ST: ROKU:ECP/i).count == 1
    puts 'udpSocket.D'

    service_line = lines.grep /LOCATION: HTTP:\/\//i
    if service_line.count == 1
      service_line = service_line[0]
      found_service = service_line.match /HTTP:\/\/.+$/i
      self.roku_service = found_service[0] if found_service.length == 1
    end
    return unless roku_service
    puts "udpSocket.E #{roku_service}"

    id_line = lines.grep /USN: UUID:ROKU:ECP:*/i
    if id_line.count == 1
      id_line = id_line[0]
      found_id = id_line.match /[^:]+$/
      self.roku_id = found_id[0] if found_id.length == 1
    end
    puts "udpSocket.F #{roku_id}"

    @socket.close
    @state = :idle
    @delegate.roku_device_found
  end

end
