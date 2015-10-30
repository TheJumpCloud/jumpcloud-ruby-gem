require 'json'
require 'base64'
require 'openssl'
require 'net/http'

class JumpCloud
  
  attr_accessor :settings
  
  def initialize(args=self.class.get_system_data)
    @settings = args
  end
  
  def update_settings(options)
    data = {}
    data.merge!(@settings) 
    options.each do |k,v|
      data[k] = v if @settings.has_key?(k) 
    end
    JumpCloud.send_to_server(data)
  end
  
  def self.get_date
    Time.now.utc.strftime("+%a, %d %h %Y %H:%M:%S GMT")
  end

  def self.parse_config
    file = '/opt/jc/jcagent.conf'
    fail file_not_found_text(file) unless File.exists?(file)
    JSON.parse(IO.read(file))
  rescue JSON::ParserError
    raise "Problem parsing #{file} as JSON; it is valid JSON?"
  end

  def self.get_key_from_config
    key = parse_config["systemKey"]
    key.nil? ? fail('systemKey not found in configuration!') : key
  end

  def self.create_signature(verb, date, system_key)
    signed_string = "#{verb} /api/systems/#{system_key} HTTP/1.1\ndate: #{date}"
    key = OpenSSL::PKey::RSA.new(client_key)
    Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, signed_string))
  end

  def self.client_key
    file = '/opt/jc/client.key'
    fail file_not_found_text(file) unless File.exists?(file)
    File.open(file)
  end

  def self.file_not_found_text(path)
    "#{path} not found, is the JumpCloud agent installed?"
  end

  def self.set_system_tags(*tags)
    system_data = get_system_data
    system_data["tags"] = tags
    send_to_server(system_data)
  end

  def self.set_system_name(system_name)
    system_data = get_system_data
    system_data["displayName"] = system_name
    send_to_server(system_data)
  end

  def self.set_sshPassEnabled
    system_data = get_system_data
    system_data["allowSshPasswordAuthentication"] = true
    send_to_server(system_data)
  end

  def self.delete_system
    date = get_date
    system_key = get_key_from_config
    signature = create_signature("DELETE", date, system_key)
    uri = URI.parse("https://console.jumpcloud.com/api/systems/#{system_key}")
    request = Net::HTTP::Delete.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request["Authorization"] = "Signature keyId=\"system/#{system_key}\",headers=\"request-line date\",algorithm=\"rsa-sha256\",signature=\"#{signature}\""
    request["Date"] = "#{date}"
    request["accept"] = "application/json"
    request["Content-Type"] = "application/json"
    http.request(request)
  end

  def self.get_system_data
    date = get_date
    system_key = get_key_from_config
    signature = create_signature("GET", date, system_key)
    uri = URI.parse("https://console.jumpcloud.com/api/systems/#{system_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = "Signature keyId=\"system/#{system_key}\",headers=\"request-line date\",algorithm=\"rsa-sha256\",signature=\"#{signature}\""
    request["Date"] = "#{date}"
    request["accept"] = "application/json"
    response = http.request(request)
    JSON.parse(response.body)
  end

  def self.send_to_server(data)
    date = get_date
    system_key = get_key_from_config
    signature = create_signature("PUT", date, system_key)
    uri = URI.parse("https://console.jumpcloud.com/api/systems/#{system_key}")
    request = Net::HTTP::Put.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request["Authorization"] = "Signature keyId=\"system/#{system_key}\",headers=\"request-line date\",algorithm=\"rsa-sha256\",signature=\"#{signature}\""
    request["Date"] = "#{date}"
    request["accept"] = "application/json"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(data)
    http.request(request)
  end

end  
