require "test_helper"

class OcrControllerTest < ActionDispatch::IntegrationTest
  test "should get upload" do
    get ocr_upload_url
    assert_response :success
  end
end
