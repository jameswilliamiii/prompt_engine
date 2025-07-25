module ActivePrompt
  class OpenAIEvalsClient
    BASE_URL = "https://api.openai.com/v1"
    
    def initialize(api_key: nil)
      @api_key = api_key || Rails.application.credentials.openai[:api_key]
    end
    
    def create_eval(name:, data_source_config:, testing_criteria:)
      post("/evals", {
        name: name,
        data_source_config: data_source_config,
        testing_criteria: testing_criteria
      })
    end
    
    def create_run(eval_id:, name:, data_source:)
      post("/evals/#{eval_id}/runs", {
        name: name,
        data_source: data_source
      })
    end
    
    def get_run(eval_id:, run_id:)
      get("/evals/#{eval_id}/runs/#{run_id}")
    end
    
    def upload_file(file_path, purpose: "evals")
      uri = URI("#{BASE_URL}/files")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      
      form_data = [
        ['purpose', purpose],
        ['file', File.open(file_path)]
      ]
      request.set_form(form_data, 'multipart/form-data')
      
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      
      JSON.parse(response.body)
    end
    
    private
    
    def post(path, body)
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json
      
      response = http.request(request)
      JSON.parse(response.body)
    end
    
    def get(path)
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
end