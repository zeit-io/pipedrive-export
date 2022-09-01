class HttpService

  require 'net/http'
  require 'net/https'


  def self.fetch_response url, timeout = 60, username = nil, secret = nil
    uri  = URI.parse url
    http = nil

    http = Net::HTTP.new uri.host, uri.port

    http.read_timeout = timeout # in seconds
    if uri.port == 443
      http.use_ssl = true
    end
    path  = uri.path.to_s
    path  = '/' if path.to_s.empty?
    query = uri.query.to_s

    user_agent = {'User-Agent' => 'https://www.VersionEye.com - https://twitter.com/VersionEye'}
    req = nil
    if query.to_s.empty?
      req = Net::HTTP::Get.new("#{path}", user_agent)
    else
      req = Net::HTTP::Get.new("#{path}?#{query}", user_agent)
    end
    if !username.to_s.empty? && !secret.to_s.empty?
      req.basic_auth username, secret
    end
    http.request(req)
  rescue => e
    Rails.logger.error "ERROR in HttpService.fetch_response(#{url}, #{timeout}) - #{e.message} - \n " + e.backtrace.join("\n") 
    nil
  end


  def self.post(url, payload, headers = {}, timeout = 60, username = nil, secret = nil)
    uri  = URI.parse url
    http = Net::HTTP.new( uri.host, uri.port )
    http.read_timeout = timeout # in seconds
    
    if uri.port == 443
      http.use_ssl = true
    end
    
    path  = uri.path.to_s
    path  = '/' if path.to_s.empty?
    query = uri.query.to_s

    if query.to_s.empty?
      request = Net::HTTP::Post.new(path, initheader = {'Content-Type' => 'text/xml'})
    else
      request = Net::HTTP::Post.new("#{path}?#{query}", initheader = {'Content-Type' => 'text/xml'})
    end
    
    if !username.to_s.empty? && !secret.to_s.empty?
      request.basic_auth username, secret
    end

    if headers && !headers.empty?
      headers.keys.each do |key|
        request[key] = headers[key]
      end
    end
    
    request.body = payload
    http.request(request)
  rescue => e 
    Rails.logger.error "ERROR in HttpService.post(#{url}, payload, #{timeout}, #{username}, secret) - #{e.message} - \n " + e.backtrace.join("\n")
    nil
  end


end
