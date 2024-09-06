class OcrController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    image_param = params[:image]

    if image_param.present?
      if image_param =~ URI::DEFAULT_PARSER.make_regexp
        response = ocr_space_request_from_url(image_param)
      else
        response = ocr_space_request_from_file(image_param)
      end

      @text = parse_ocr_response(response)
      render :show
    else
      render json: { error: "Please upload a File or image URL" }, status: :bad_request
    end
  end

  private

  def ocr_space_request(file)
    api_key = K82778956688957
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
    response.parsed_response
  end

  def ocr_space_request_from_url(url)
    api_key = K82778956688957
    response = HTTParty.post(
      "https://api.ocr.space/parse/image",
      body: {
        apikey: api_key,
        isOverlayRequired: false,
        url: url
      },
    )
    response.parsed_response
  end

  def parse_ocr_response(response)
    parsed_results = response["ParsedResults"]
    return "No Text found" if parsed_results.empty?

    parsed_results.map { |result| result["ParsedText"] }.join("/n")
  end
end
