class OcrController < ApplicationController

  require "mini_magick"
  require "open-uri"

  def create
    Rails.logger.debug("Using API Key: #{ENV['OCR_API_KEY']}")
    Rails.logger.info("Received params: #{params.inspect}")
    
    image_param = params[:image]

    if image_param.present?
      begin
      processed_image = process_image(image_param)
      Rails.logger.info("Processed image type: #{processed_image.class}")

        if processed_image.is_a?(Tempfile)
          Rails.logger.info("Processing image from temporary file: #{processed_image.path}")
          response = ocr_space_request_from_file(processed_image)
        elsif processed_image.is_a?(String) && processed_image =~ URI::DEFAULT_PARSER.make_regexp
          Rails.logger.info("Processing image from URL: #{processed_image}")
          response = ocr_space_request_from_url(processed_image)
        else
          raise StandardError, "Unexpected result from process_image: #{processed_image.class}"
        end

        @text = parse_ocr_response(response)
        render json: {text: @text}, status: :ok
      rescue => e
        Rails.logger.error("Error in create action: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { error: "Failed to process image: #{e.message}"}, status: :unprocessable_entity
      ensure
        processed_image.close if processed_image.is_a?(Tempfile)
      end
    else
      render json: { error: "Please upload a File or image URL" }, status: :bad_request
    end
  end

  private

  def process_image(image_param)
    Rails.logger.info("Starting image processing")
    begin
      if image_param.is_a?(String) && image_param =~ URI::DEFAULT_PARSER.make_regexp
        Rails.logger.info("Processing URL: #{image_param}")
        image = MiniMagick::Image.open(image_param)
      else
        Rails.logger.info("Processing uploaded file")
        image = MiniMagick::Image.read(image_param.read)
      end

      Rails.logger.info("Image opened successfully")

      image.resize '1024x1024>'
      Rails.logger.info("Image resized")

      image.quality '85'
      Rails.logger.info("Image compressed")

      temp_file = Tempfile.new(['processed', '.jpg'])
      image.write(temp_file.path)
      Rails.logger.info("Image saved to temporary file: #{temp_file.path}")

      temp_file.rewind
      temp_file
    rescue => e
      Rails.logger.error("Error processing image: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise e
    end
  end

  def ocr_space_request_from_file(file)
    api_key = ENV["OCR_API_KEY"]
    Rails.logger.info("Sending file to OCR service: #{file.path}")
    
    request_body = {
      apikey: api_key,
      isOverlayRequired: false,
      file: File.open(file.path, 'rb'),
      filetype: 'JPG',
      OCREngine: 2
    }
    
    Rails.logger.info("OCR request body: #{request_body.inspect}")
    
    response = HTTParty.post(
      "https://api.ocr.space/parse/image",
      multipart: true,
      body: request_body
    )
    
    Rails.logger.debug("OCR Service Response: #{response.body}")
    response.parsed_response
  end

  def ocr_space_request_from_url(url)
    api_key = ENV["OCR_API_KEY"]
    Rails.logger.info("Sending URL to OCR service: #{url}")
    
    request_body = {
      apikey: api_key,
      isOverlayRequired: false,
      url: url,
      filetype: 'JPG',
      OCREngine: 2
    }
    
    Rails.logger.info("OCR request body: #{request_body.inspect}")
    
    response = HTTParty.post(
      "https://api.ocr.space/parse/image",
      body: request_body
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
    Rails.logger.error(e.backtrace.join("\n"))
    "Error occured while processing the image"
  end
end
