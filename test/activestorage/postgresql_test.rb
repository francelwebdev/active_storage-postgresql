# frozen_string_literal: true

require "activestorage/shared_service_tests"
class ActiveStorage::Service::PostgreSQLServiceTest < ActiveSupport::TestCase
  SERVICE  = ActiveStorage::Service.configure(:postgresql, {postgresql: {service: "PostgreSQL"}})

  setup do
    ActiveStorage::Current.host = "https://example.com"
  end

  teardown do
    ActiveStorage::Current.reset
  end

  include ActiveStorage::Service::SharedServiceTests

  test "uploading file with integrity" do
    begin
      key  = SecureRandom.base58(24)
      data = "Something else entirely!"
      file = Tempfile.open("upload")
      file.write(data)
      file.rewind
      @service.upload(key, file, checksum: Digest::MD5.base64digest(data))
      assert_equal data, @service.download(key)
    ensure
      @service.delete key
    end
  end

  test "uploading file without integrity" do
    begin
      key  = SecureRandom.base58(24)
      data = "Something else entirely!"
      file = Tempfile.open("upload")
      file.write(data)
      file.rewind

      assert_raises(ActiveStorage::IntegrityError) do
        @service.upload(key, file, checksum: Digest::MD5.base64digest("bad data"))
      end

      assert_not @service.exist?(key)
    ensure
      @service.delete key
    end
  end

  test "url generation" do
    assert_match(/^https:\/\/example.com\/rails\/active_storage\/disk\/.*\/avatar\.png\?content_type=image%2Fpng&disposition=inline/,
      @service.url(FIXTURE_KEY, expires_in: 5.minutes, disposition: :inline, filename: ActiveStorage::PostgreSQL::Filename.new("avatar.png"), content_type: "image/png"))
  end

  test "headers_for_direct_upload generation" do
    assert_equal({ "Content-Type" => "application/json" }, @service.headers_for_direct_upload(FIXTURE_KEY, content_type: "application/json"))
  end
end
