require 'json'
require 'base64'
require 'openssl'

class JumpCloud
  def self.get_date
    now = Time.now.utc.strftime("+%a, %d %h %Y %H:%M:%S GMT")
  end

  def self.parse_config
    jc_conf = JSON.parse( IO.read("/opt/jc/jcagent.conf") )
  end

  def self.get_key_from_config
    jc_conf = parse_config["systemKey"]
  end

  def self.create_signature(date, system_key)
    signed_string = "PUT /api/systems/#{system_key} HTTP/1.1\ndate: #{date}"
    key = OpenSSL::PKey::RSA.new(File.open("/opt/jc/client.key"))
    Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, signed_string))
  end

  def self.set_system_tags(*tags)
    tags_list = tags.join(%(\\\",\\\"))
    data = %("{\\\"tags\\\" : [\\\"#{tags_list}\\\"]}")
    post_to_server(data)
  end


  def self.set_system_tag(tag_id)
    data = %("{\\\"tags\\\" : [\\\"#{tag_id}\\\"]}")
    post_to_server(data)
  end

  def self.set_system_name(system_name)
    data = %("{\\\"displayName\\\" : \\\"#{system_name}\\\"}")
    post_to_server(data)
  end

  def self.post_to_server(data)
    date = get_date
    system_key = get_key_from_config
    signature = create_signature(date, system_key)
    command = %(curl -iq -d #{data} -X "PUT" -H "Content-Type: application/json" -H "Accept: application/json" -H "Date: #{date}" -H "Authorization: Signature keyId=\\\"system/#{system_key}\\\",headers=\\\"request-line date\\\",algorithm=\\\"rsa-sha256\\\",signature=\\\"#{signature}\\\"" --url https://console.jumpcloud.com/api/systems/#{system_key})
    `#{command}`
  end

end  
