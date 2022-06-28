class PipelineExportService


  def self.export pipe_name = "test"
    url = "https://api.pipedrive.com/v1/pipelines?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url

    pipes = JSON.parse response.body
    pipes["data"].each do |pipe|
      if pipe["name"].to_s.eql?(pipe_name)
        p "process #{pipe["name"].to_s}"
        self.process( pipe )
      else 
        p "skip #{pipe["name"].to_s}"
      end
    end 
  end


  def self.process pipe 
    url = "https://api.pipedrive.com/v1/pipelines/#{pipe['id']}?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response.nil? || response.code.to_i > 201
      p "ERROR with pipe #{pipe['id']}"
      return nil 
    end

    pipe_detail = JSON.parse response.body
    File.open("exports/pipe_#{pipe['id']}.json","w") do |f|
      f.write(pipe_detail)
    end

    self.process_pipe_deals pipe_detail
  end


  def self.process_pipe_deals pipe 
    url = "https://api.pipedrive.com/v1/pipelines/#{pipe['data']['id']}/deals?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response.nil? || response.code.to_i > 201
      p "ERROR with pipe deals for pipe #{pipe['data']['id']} - #{response.code} - #{response.body}"
      return nil 
    end

    deals = JSON.parse response.body
    deals["data"].each do |deal| 
      self.process_deal pipe['data']['id'], deal['id']  
    end
  end


  def self.process_deal pipe_id, deal_id 
    url = "https://api.pipedrive.com/v1/deals/#{deal_id}?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response.nil? || response.code.to_i > 201
      p "ERROR with deal #{deal_id} - #{response.code} - #{response.body}"
      return nil 
    end

    p "process pipe #{pipe_id} and deal #{deal_id}"
    deal = JSON.parse response.body
    File.open("exports/pipe_#{pipe_id}_deal_#{deal_id}.json","w") do |f|
      f.write(deal)
    end

    self.process_deal_flow( pipe_id, deal_id )
    self.process_deal_mails( pipe_id, deal_id )
    self.process_deal_persons( pipe_id, deal_id )
  end


  def self.process_deal_flow pipe_id, deal_id
    url = "https://api.pipedrive.com/v1/deals/#{deal_id}/flow?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response.nil? || response.code.to_i > 201
      p "ERROR with deal flow #{deal_id} - #{response.code} - #{response.body}"
      return nil 
    end

    deal = JSON.parse response.body
    File.open("exports/pipe_#{pipe_id}_deal_#{deal_id}_flow.json","w") do |f|
      f.write(deal)
    end    
  end


  def self.process_deal_mails pipe_id, deal_id
    url = "https://api.pipedrive.com/v1/deals/#{deal_id}/mailMessages?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response.nil? || response.code.to_i > 201
      p "ERROR with deal mailMessages #{deal_id} - #{response.code} - #{response.body}"
      return nil 
    end

    deal = JSON.parse response.body
    File.open("exports/pipe_#{pipe_id}_deal_#{deal_id}_mailMessages.json","w") do |f|
      f.write(deal)
    end    
  end


  def self.process_deal_persons pipe_id, deal_id
    url = "https://api.pipedrive.com/v1/deals/#{deal_id}/persons?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response.nil? || response.code.to_i > 201
      p "ERROR with deal persons #{deal_id} - #{response.code} - #{response.body}"
      return nil 
    end

    deal = JSON.parse response.body
    File.open("exports/pipe_#{pipe_id}_deal_#{deal_id}_persons.json","w") do |f|
      f.write(deal)
    end    
  end


end