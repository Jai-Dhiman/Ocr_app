class OcrController < ApplicationController
  def upload
    #Save uploaded file
    uploaded_file = params[:file]
    file_path = Rails.root.join('tmp', uploaded_file.original_filename)

    File.open(file_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end

    #perform OCR
    text = perform_ocr(file_path)

    #send extracted text as JSON response
    render json: {text: text}
  ensure
    #clean up temporary file
    File.delete(file_path) if File.exist?(file_path)
  end

  private

  def perform_ocr(file_path)
    #initialize Tesseract engine
    engine = Tesseract::Engine.new
    #process the image
    engine.text_for(file_path)
  end
end
