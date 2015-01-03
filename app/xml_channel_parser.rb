class XmlChannelParser
  attr_accessor :channels

  def initialize
    @in_root = false
    self.channels = {}
  end

  def parser(parser, didStartElement: element_name, namespaceURI: _namespace_uri, qualifiedName: _qualified_name, attributes: attributes)
    unless @in_root
      @in_root = true
      return
    end

    @current_channel = { :id => attributes['id'], :name => '' }
  end

  def parser(parser, foundCharacters: node_content)
    @current_channel[:name] += node_content if @current_channel
  end

  def parser(parser, didEndElement: element_name, namespaceURI: _namespace_uri, qualifiedName: _qualified_name)
    return unless @current_channel
    channels[@current_channel[:name]] = @current_channel[:id]
    @current_channel = nil
  end
end
