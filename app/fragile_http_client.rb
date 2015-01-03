class FragileHttpClient < NSObject

  def self._url_components(url)
    fail 'Missing or invalid request protocol.' unless url.match /^HTTP:\/\//i
    components = url.match /^HTTP:\/\/([^:\/]+)(:[0-9]+)?(\/.+)?$/i
    fail 'Invalid request URL.' if components.nil?
    host    = components[1]
    port    = components[2].nil? ? 80 : components[2][1..components[2].length-1].to_i
    request = components[3].nil? ? '/' : components[3]
    return host, port, request
  end

  def self.get(url, block)
    begin
      host, port, request = _url_components url
    rescue
      block.call nil, 'Invalid request URL.' unless block.nil?
      return
    end

    http = FragileHttpClient.new host, port, request, block
    http._get
  end


  def initialize(host, port, request, block)
    @host    = host
    @port    = port
    @request = request
    @block   = block
    @socket  = GCDAsyncSocket.alloc.initWithDelegateOnMainQueue self
  end

  def cleanup(response, error)
    @socket.setDelegate nil
    @socket.disconnect
    @socket = nil
    @me = nil
    @block.call response, error unless @block.nil?
  end

  def _get
    @type = :get
    @me   = self # nobody has a reference to us; don't get collected

    error_ptr = Pointer.new :object
    unless @socket.connectToHost @host, onPort: @port, error: error_ptr
      cleanup nil, 'Unable to connect to Roku. Bad address?'
      return
    end
  end

  def socket(socket, didConnectToHost: host, port: port)
    if @type == :get
      data = "GET #{@request} HTTP/1.1\r\n" \
             "Host: #{host}\r\n"            \
             "Connection: Close\r\n\r\n"
      @socket.writeData data.dataUsingEncoding(NSUTF8StringEncoding), withTimeout:3.0, tag:0
      terminator = "\r\n\r\n".dataUsingEncoding NSUTF8StringEncoding
      @state = :header
      @socket.readDataToData terminator, withTimeout:5.0, tag:0
    end
  end

  def socket(socket, didReadData: data, withTag: tag)
    response = NSString.alloc.initWithData data, encoding:NSUTF8StringEncoding

    if @state == :header
      content_length = nil

      unless response.nil?
        lines = response.gsub("\r\n", "\n").split "\n"
        if (!lines.nil?) && (lines.length > 1) && (lines.grep(/HTTP\/[0-9](\.[0-9]) 200 OK/).count == 1)
          match = lines.grep /^CONTENT-LENGTH: ([0-9]+)$/i
          if match.length == 1
            content_length = match[0].match(/[0-9]+$/)[0].to_i
          end
        end
      end

      if content_length.nil?
        cleanup nil, 'Error communicating with Roku. Unusable HTTP response.'
        return
      end

      @state = :body
      @socket.readDataToLength content_length, withTimeout:5.0, tag:0
    elsif @state == :body
      cleanup response, nil
    end
  end

end
