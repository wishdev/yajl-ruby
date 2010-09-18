# encoding: UTF-8
require 'yajl' unless defined?(Yajl::Parser)

module JSON
  class JSONError < StandardError; end unless defined?(JSON::JSONError)
  class ParserError < JSONError; end unless defined?(JSON::ParserError)

  def self.deep_const_get(path) # :nodoc:
    path.to_s.split(/::/).inject(Object) do |p, c|
      case
      when c.empty?             then p
      when p.const_defined?(c)  then p.const_get(c)
      else
        begin
          p.const_missing(c)
        rescue NameError
          raise ArgumentError, "can't find const #{path}"
        end
      end
    end
  end

  def self.default_options
    @default_options ||= {:symbolize_keys => false}
  end

  def self.parse(str, opts=JSON.default_options)
    begin
      data = Yajl::Parser.parse(str, opts)
      if data.class == Hash && data['json_class'] && deep_const_get(data['json_class']).json_creatable?
        data = deep_const_get(data['json_class']).json_create(data)
      end
      data
    rescue Yajl::ParseError => e
      raise JSON::ParserError, e.message
    end
  end

  def self.load(input, *args)
    begin
      Yajl::Parser.parse(input, default_options)
    rescue Yajl::ParseError => e
      raise JSON::ParserError, e.message
    end
  end
end

class ::Class
  # Returns true, if this class can be used to create an instance
  # from a serialised JSON string. The class has to implement a class
  # method _json_create_ that expects a hash as first parameter, which includes
  # the required data.
  def json_creatable?
    respond_to?(:json_create)
  end
end