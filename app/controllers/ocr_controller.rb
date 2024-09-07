class OcrController < ApplicationController

  def create
    Rails.logger.debug("Using API Key: #{ENV['OCR_API_KEY']}")
    Rails.logger.info("Received params: #{params.inspect}")
    
    image_param = params[:image]

    if image_param.present?
      if image_param =~ URI::DEFAULT_PARSER.make_regexp
        response = ocr_space_request_from_url(image_param)
      else
        response = ocr_space_request_from_file(image_param)
      end

      @text = parse_ocr_response(response)
      render json: {text: @text}, status: :ok
    else
      render json: { error: "Please upload a File or image URL" }, status: :bad_request
    end
  end

  private

  def ocr_space_request_from_file(file)
    api_key = ENV["OCR_API_KEY"]
    response = HTTParty.post(
      "https://api.ocr.space/parse/image",
      body: {
        apikey: api_key,
        isOverlayRequired: false
      },
      files: {
        "file" => file
      }
    )
    Rails.logger.debug("OCR Service Response: #{response.body}")
    response.parsed_response
  end

  def ocr_space_request_from_url(url)
    api_key = ENV["OCR_API_KEY"]
    response = HTTParty.post(
      "https://api.ocr.space/parse/image",
      body: {
        apikey: api_key,
        isOverlayRequired: false,
        url: url
      },
    )
    Rails.logger.debug("OCR Service Response: #{response.body}")
    response.parsed_response
  end

  def parse_ocr_response(response)
    Rails.logger.debug("Parsing OCR response: #{response.inspect}")
    return "No response from OCR service" if response.nil?

    parsed_results = response["ParsedResults"]
    Rails.logger.debug("Parsed Results: #{parsed_results.inspect}")
    return "No Text found in the image" if parsed_results.nil? || parsed_results.empty?

    text = parsed_results.map { |result| result["ParsedText"] }.join("\n")
    Rails.logger.debug("Extracted Text: #{text}")
    text
  rescue => e
    Rails.logger.error("Error parsing OCR response: #{e.message}")
    "Error occured while processing the image"
  end
end
