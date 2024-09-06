class OcrController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    uploaded_file = params[:image]
    if uploaded_file
      response = ocr_space_request(uploaded_file)
      @text = parse_ocr_response(response)
      render :show
    else
      render json: { error: "Please upload a File" }, status: :bad_request
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

  def parse_ocr_response(response)
    parsed_results = response["ParsedResults"]
    return "No Text found" if parsed_results.empty?

    parsed_results.map { |result| result["ParsedText"] }.join("/n")
  end
end
