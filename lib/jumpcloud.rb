require 'json'
require 'base64'
require 'openssl'
require 'net/http'

class JumpCloud
  
  attr_accessor :settings

  @jc_directory = "/opt/jc/"

  def initialize( dir="/opt/jc/" )
    @jc_directory = dir
  end
  
  def initialize(args=self.class.get_system_data())
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
    JSON.parse( IO.read(File.Join(@jc_directory, "jcagent.conf") ))
  end

  def self.get_key_from_config
    parse_config["systemKey"]
  end

  def self.create_signature(verb, date, system_key)
    signed_string = "#{verb} /api/systems/#{system_key} HTTP/1.1\ndate: #{date}"
    key = OpenSSL::PKey::RSA.new(File.open(File.Join(@jc_directory,"client.key")))
    Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, signed_string))
  end

  def self.set_system_tags(*tags)
    system_data = get_system_data()
    system_data["tags"] = tags
    send_to_server(system_data)
  end

  def self.set_system_name(system_name)
    system_data = get_system_data()
    system_data["displayName"] = system_name
    send_to_server(system_data)
  end

  def self.set_sshPassEnabled()
    system_data = get_system_data()
    system_data["allowSshPasswordAuthentication"] = true
    send_to_server(system_data)
  end

  def self.delete_system()
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
    response = http.request(request)
  end

  def self.get_system_data()
    date = get_date
    system_key = get_key_from_config
    signature = create_signature("GET", date, system_key)
    uri = URI.parse("https://console.jumpcloud.com/api/systems/#{system_key}")
    request = Net::HTTP.new(uri.host, uri.port)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = "Signature keyId=\"system/#{system_key}\",headers=\"request-line date\",algorithm=\"rsa-sha256\",signature=\"#{signature}\""
    request["Date"] = "#{date}"
    request["accept"] = "application/json"

    response = http.request(request)
    return JSON.parse(response.body)
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
    response = http.request(request)
  end

end  
