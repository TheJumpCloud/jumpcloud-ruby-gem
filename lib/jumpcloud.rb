require 'json'
require 'base64'
require 'openssl'
require 'net/http'

class JumpCloud
  def self.get_date
    Time.now.utc.strftime("+%a, %d %h %Y %H:%M:%S GMT")
  end

  def self.parse_config
    JSON.parse( IO.read("/opt/jc/jcagent.conf") )
  end

  def self.get_key_from_config
    parse_config["systemKey"]
  end

  def self.create_signature(verb, date, system_key)
    signed_string = "#{verb} /api/systems/#{system_key} HTTP/1.1\ndate: #{date}"
    key = OpenSSL::PKey::RSA.new(File.open("/opt/jc/client.key"))
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

  def self.get_system_data()
    date = get_date
    system_key = get_key_from_config
    signature = create_signature("GET", date, system_key)
    uri = URI("https://console.jumpcloud.com/api/systems/#{system_key}")
    request = Net::HTTP::Get.new(uri)
    #request.set_content_type("application/json")
    request.add_field("Authorization", "Signature keyId=\"system/#{system_key}\",headers=\"request-line date\",algorithm=\"rsa-sha256\",signature=\"#{signature}\"")
    request.add_field("Date", "#{date}")
    request.add_field("accept", "application/json")
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.ssl_version = :SSLv3
      response = http.request(request)
      return JSON.parse(response.body)
    end
  end

  def self.send_to_server(data)
    date = get_date
    system_key = get_key_from_config
    signature = create_signature("PUT", date, system_key)
    uri = URI("https://console.jumpcloud.com/api/systems/#{system_key}")
    request = Net::HTTP::Put.new(uri)
    request.set_content_type("application/json")
    request.add_field("Authorization", "Signature keyId=\"system/#{system_key}\",headers=\"request-line date\",algorithm=\"rsa-sha256\",signature=\"#{signature}\"")
    request.add_field("Date", "#{date}")
    request.add_field("accept", "application/json")
    request.body = JSON.generate(data)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.ssl_version = :SSLv3
      http.request(request)
    end
  end

end  
