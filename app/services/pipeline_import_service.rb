class PipelineImportService


  def self.import pipe_id = "pipe_15"
    url = "https://api.pipedrive.com/v1/pipelines?api_token=#{ENV['TOKEN']}"

    file = File.open "exports/#{pipe_id}.json"
    pipe_data = eval file.read 

    pipe_name = pipe_data['data']['name']
    pipe_object = self.fetch_pipe_by_name( pipe_name )
    if pipe_object.nil? 
      payload = {:name => pipe_name}
      resp = HttpService.post url, payload.to_json, {"Content-Type": "application/json"}
      if resp.code.to_i != 200 && resp.code.to_i != 201 
        p "response code: #{resp.code} - #{resp.body}"
        return nil 
      end

      pipe_object = self.fetch_pipe_by_name( pipe_name )
    end
    
    stages_file = File.open "exports/#{pipe_id}_stages.json"
    stages_cont = eval stages_file.read 
    stages_data = stages_cont['data']
    stages_data.each do |stage|
      stage_object = self.fetch_stage_by stage['name'], pipe_object['id']
      next if stage_object

      self.create_pipe_stage stage['name'], pipe_object['id']
    end

    # Create Deals
    # Iterate over all deal files 
    deals_hash = Hash.new
    Dir["exports/#{pipe_id}_deal_*.json"].each do |file|
      # skip all files which do not end with a number.json. 
      # skip all files ending with [_flow, _mailMessages, _persons].json
      next if file.match(/exports\/pipe_\d+_deal_\d+.json/i).nil?

      deal_file  = File.open file
      deal_cont  = eval deal_file.read 
      deal_data  = deal_cont['data']
      deal_title = deal_data['title']
      deal_id    = deal_data['id']
      deals_hash[deal_id] = deal_title

      # stage_name = self.find_stage_name_for( stages_data, deal_data['stage_id'] )
      # stage_obj = self.fetch_stage_by stage_name, pipe_object['id']
      # stage_id = stage_obj['id']

      # if self.create_deal( deal_title, pipe_object['id'], stage_id, deal_data['status'] ) == true 
      #   p "Created deal '#{deal_title}' in stage #{stage_name}"
      # else 
      #   p " - Could not create deal '#{deal_title}'"
      # end
    end

    # Create Notes 
    # Iterate over all flow files
    Dir["exports/#{pipe_id}_deal_*.json"].each do |file|
      next if file.match(/exports\/pipe_\d+_deal_\d+_flow.json/i).nil?

      flow_file = File.open file
      flow_cont = eval flow_file.read 
      flow_data = flow_cont['data']
      flow_data.each do |flow|
        next if flow['object'].to_s.eql?('note') == false 

        fdata = flow['data']
        if fdata['deal_id'].to_i < 1544 
          p "skip notes for deal #{fdata['deal_id']}"
        end

        f_deal_id = fdata['deal_id']
        f_deal_title = deals_hash[f_deal_id]
        p_deal_id = fetch_deal_id_by( f_deal_title )

        if self.create_note( p_deal_id, fdata['content'], fdata['add_time'] ) == true
          p "Created note for deal #{fdata['deal_id']}"
        else 
          p " - Could not create note for deal #{fdata['deal_id']}"
        end
      end
    end

    nil
  end


  def self.find_stage_name_for( stages_data, stage_id )
    stages_data.each do |stage|
      return stage['name'] if stage['id'].to_s.eql?(stage_id.to_s)
    end 
    p "no stage name found for stage_id #{stage_id}"
    nil
  end


  def self.create_deal title, pipe_id, stage_id, status
    url = "https://api.pipedrive.com/v1/deals?api_token=#{ENV['TOKEN']}"
    payload = { :title => title, 
                :pipeline_id => pipe_id,
                :stage_id => stage_id,
                :status => status,
                :visible_to => "3" }
    resp = HttpService.post url, payload.to_json, {"Content-Type": "application/json"}
    if resp.code.to_i != 200 && resp.code.to_i != 201 
      p payload
      p "ERROR in create_deal. Response code: #{resp.code} - #{resp.body}"
      return nil 
    end

    true
  end


  def self.create_pipe_stage stage_name, pipe_id
    url = "https://api.pipedrive.com/v1/stages?api_token=#{ENV['TOKEN']}"
    payload = { :name => stage_name, :pipeline_id => pipe_id }
    resp = HttpService.post url, payload.to_json, {"Content-Type": "application/json"}
    if resp.code.to_i != 200 && resp.code.to_i != 201 
      p payload
      p "ERROR in create_pipe_stage. Response code: #{resp.code} - #{resp.body}"
      return nil 
    end

    true 
  end


  def self.create_note deal_id, content, add_time
    return false if content.to_s.strip.empty? 

    url = "https://api.pipedrive.com/v1/notes?api_token=#{ENV['TOKEN']}"
    payload = { :content => content, 
                :deal_id => deal_id,
                :add_time => add_time }
    resp = HttpService.post url, payload.to_json, {"Content-Type": "application/json"}
    if resp.code.to_i != 200 && resp.code.to_i != 201 
      p payload
      p "ERROR in create_note. Response code: #{resp.code} - #{resp.body}"
      return nil 
    end

    true 
  end


  def self.import_orgas 
    url = "https://api.pipedrive.com/v1/organizations?api_token=#{ENV['TOKEN']}&start=0&limit=500"
    response = HttpService.fetch_response url
    if response.code.to_i != 200 
      p "could not load orgas"
      return 
    end 

    orgas = JSON.parse response.body
    files = []
    names = []
    Dir["exports/*.json"].each do |file_name|
      next if file_name.match(/pipe_\d+_deal_\d+.json/i).nil? 
        
      files.push file_name
      self.import_orga_from orgas, names, file_name
      self.import_person_from orgas, file_name
    end
    files 
  end


  def self.import_person_from orgas, file_name
    content = eval File.read file_name
    data = content["data"]
    if data["org_id"].to_s.strip.empty?
      p "skip #{file_name} because no orga found"
      return nil 
    end

    if data["org_id"].to_s.strip.empty?
      p "skip #{file_name} because no orga found"
      return nil 
    end

    if data["person_id"].to_s.strip.empty?
      p "no person data found. Skip this one."
      return nil
    end

    person_name = data["person_id"]["name"]
    url = "https://api.pipedrive.com/v1/persons?api_token=#{ENV['TOKEN']}&start=0&limit=500"
    response = HttpService.fetch_response url
    if response.code.to_i != 200 
      p "could not load persons"
      return 
    end 

    content = JSON.parse response.body
    persons = content["data"]
    persons.each do |person|
      if person["name"].to_s.eql?(person_name)
        p "Person #{person_name} exists already"
        return nil
      end
    end

    orga_name = data["org_id"]["name"]
    orga_id = self.orga_id_for orgas, orga_name
    url = "https://api.pipedrive.com/v1/persons?api_token=#{ENV['TOKEN']}"
    payload = {:name => person_name, 
               :email => data["person_id"]["email"], 
               :org_id => orga_id,
               :visible_to => 3}
    resp = HttpService.post url, payload.to_json, {"Content-Type": "application/json"}
    if resp.code.to_i != 200 && resp.code.to_i != 201 
      p payload
      p "ERROR response code: #{resp.code} - #{resp.body}"
      return nil 
    end

    p "SUCCESS person #{person_name} created!"
    p "--"
  end


  def self.import_orga_from orgas, names, file_name
    content = eval File.read file_name
    data = content["data"]
    if data["org_id"].to_s.strip.empty?
      p "skip #{file_name} because no orga found"
      return nil 
    end

    orga_name = data["org_id"]["name"]
    if names.include?(orga_name)
      p "orga #{orga_name} exists already .. "
      return nil 
    end

    if self.orga_exists?(orgas, orga_name) 
      p "orga #{orga_name} exists already"
      return nil 
    end

    url = "https://api.pipedrive.com/v1/organizations?api_token=#{ENV['TOKEN']}"
    payload = {:name => orga_name, :visible_to => 3}
    resp = HttpService.post url, payload.to_json, {"Content-Type": "application/json"}
    if resp.code.to_i != 200 && resp.code.to_i != 201 
      p "ERROR response code: #{resp.code} - #{resp.body}"
      return nil 
    end

    p "SUCCESS orga #{orga_name} created!"
    names.push orga_name
  end


  def self.orga_exists? orgas, name 
    orgas["data"].each do |orga|
      if orga["name"].to_s.downcase.eql?(name.to_s.downcase)
        return true 
      end
    end
    return false 
  end


  def self.orga_id_for orgas, name 
    orgas["data"].each do |orga|
      if orga["name"].to_s.downcase.eql?(name.to_s.downcase)
        return orga["id"].to_s
      end
    end
    return nil
  end


  def self.fetch_pipe_by_name pipe_name
    return nil if pipe_name.to_s.empty? 

    url = "https://api.pipedrive.com/v1/pipelines?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response.code.to_i != 200 
      p "could not load pipelines!"
      return nil
    end 

    pipelines = JSON.parse response.body
    pipelines['data'].each do |pipe|
      return pipe if pipe['name'].to_s.eql?(pipe_name.to_s)
    end

    nil
  end


  def self.fetch_stage_by stage_name, pipe_id
    return nil if stage_name.to_s.empty? || pipe_id.to_s.empty?

    url = "https://api.pipedrive.com/v1/stages?api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response.code.to_i != 200 
      p "could not load stages!"
      return nil
    end 

    stages = JSON.parse response.body
    stages['data'].each do |stage|
      return stage if stage['name'].to_s.eql?(stage_name.to_s) && stage['pipeline_id'].to_s.eql?(pipe_id.to_s)
    end

    nil
  end


  def self.fetch_deal_id_by deal_title
    return nil if deal_title.to_s.empty?

    deal_title_enc = CGI.escape deal_title
    url = "https://api.pipedrive.com/v1/deals/search?fields=title&term=#{deal_title_enc}&api_token=#{ENV['TOKEN']}"
    response = HttpService.fetch_response url
    if response && response.code.to_i != 200 
      p "could not load deals!"
      return nil
    end 

    results = JSON.parse response.body
    results['data']['items'].each do |item|
      return item['item']['id'] if item['item']['title'].to_s.eql?(deal_title.to_s)
    end

    nil
  end


end
