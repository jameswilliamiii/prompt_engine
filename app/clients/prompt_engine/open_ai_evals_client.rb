module PromptEngine
  class OpenAiEvalsClient
    BASE_URL = "https://api.openai.com/v1"

    class APIError < StandardError; end
    class AuthenticationError < APIError; end
    class RateLimitError < APIError; end
    class NotFoundError < APIError; end

    def initialize(api_key: nil)
      # Try to get API key from: 1) parameter, 2) Settings, 3) Rails credentials
      @api_key = api_key || fetch_api_key_from_settings || Rails.application.credentials.dig(:openai, :api_key)
      raise AuthenticationError, "OpenAI API key not configured" if @api_key.blank?
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

      File.open(file_path, "rb") do |file|
        form_data = [
          [ "purpose", purpose ],
          [ "file", file, { filename: File.basename(file_path) } ]
        ]
        request.set_form(form_data, "multipart/form-data")

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        handle_response(response)
      end
    rescue Errno::ENOENT => e
      raise APIError, "File not found: #{file_path}"
    rescue => e
      raise APIError, "File upload failed: #{e.message}"
    end

    private

    def fetch_api_key_from_settings
              PromptEngine::Setting.instance.openai_api_key
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def post(path, body)
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      response = http.request(request)
      handle_response(response)
    rescue Net::ReadTimeout => e
      raise APIError, "Request timed out"
    rescue Net::OpenTimeout => e
      raise APIError, "Connection timed out"
    rescue => e
      raise APIError, "Request failed: #{e.message}"
    end

    def get(path)
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"

      response = http.request(request)
      handle_response(response)
    rescue Net::ReadTimeout => e
      raise APIError, "Request timed out"
    rescue Net::OpenTimeout => e
      raise APIError, "Connection timed out"
    rescue => e
      raise APIError, "Request failed: #{e.message}"
    end

    def handle_response(response)
      case response.code.to_i
      when 200..299
        JSON.parse(response.body)
      when 401
        raise AuthenticationError, "Invalid API key"
      when 404
        raise NotFoundError, parse_error_message(response)
      when 429
        raise RateLimitError, "Rate limit exceeded. Please try again later."
      when 400..499
        raise APIError, "Client error: #{parse_error_message(response)}"
      when 500..599
        raise APIError, "Server error: #{parse_error_message(response)}"
      else
        raise APIError, "Unexpected response: #{response.code} - #{response.body}"
      end
    end

    def parse_error_message(response)
      body = JSON.parse(response.body)
      body.dig("error", "message") || body["error"] || response.body
    rescue JSON::ParserError
      response.body
    end
  end
end
