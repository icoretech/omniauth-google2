# frozen_string_literal: true

require_relative "test_helper"

require "json"
require "uri"

class OmniauthGoogle2Test < Minitest::Test
  TOKEN_SCOPE = "https://www.googleapis.com/auth/userinfo.profile " \
                "https://www.googleapis.com/auth/userinfo.email openid"

  def build_strategy
    OmniAuth::Strategies::Google2.new(nil, "client-id", "client-secret")
  end

  def test_uses_current_google_endpoints
    client_options = build_strategy.options.client_options

    assert_equal "https://openidconnect.googleapis.com", client_options.site
    assert_equal "https://accounts.google.com/o/oauth2/v2/auth", client_options.authorize_url
    assert_equal "https://oauth2.googleapis.com/token", client_options.token_url
  end

  def test_supports_google_oauth2_strategy_name_for_compatibility
    legacy_strategy = OmniAuth::Strategies::GoogleOauth2.new(nil, "client-id", "client-secret")

    assert_equal "google_oauth2", legacy_strategy.options.name
    assert_equal "https://accounts.google.com/o/oauth2/v2/auth", legacy_strategy.options.client_options.authorize_url
  end

  def test_normalizes_scope_and_defaults_access_type
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for("/auth/google2?scope=email,profile"))
    strategy.define_singleton_method(:request) { request }
    strategy.define_singleton_method(:session) { {} }

    params = strategy.authorize_params

    assert_equal "email profile", params[:scope]
    assert_equal "offline", params[:access_type]
  end

  def test_uid_info_credentials_and_extra_are_derived_from_raw_info
    strategy = build_strategy
    payload = {
      "sub" => "123456789012345678901",
      "name" => "Sample Person",
      "email" => "sample@example.test",
      "email_verified" => true,
      "given_name" => "Sample",
      "picture" => "https://lh3.googleusercontent.com/example-photo=s96-c"
    }

    token = FakeAccessToken.new(payload)
    strategy.define_singleton_method(:access_token) { token }
    strategy.define_singleton_method(:decode_id_token) do |_id_token|
      {
        "iss" => "https://accounts.google.com",
        "aud" => "client-id",
        "sub" => "123456789012345678901",
        "email" => "sample@example.test",
        "email_verified" => true,
        "name" => "Sample Person",
        "picture" => "https://lh3.googleusercontent.com/example-photo=s96-c",
        "given_name" => "Sample",
        "iat" => 1_772_689_518,
        "exp" => 1_772_693_118
      }
    end

    assert_equal "123456789012345678901", strategy.uid
    assert_equal(
      {
        name: "Sample Person",
        email: "sample@example.test",
        unverified_email: "sample@example.test",
        email_verified: true,
        first_name: "Sample",
        image: "https://lh3.googleusercontent.com/example-photo=s96-c"
      },
      strategy.info
    )
    assert_equal(
      {
        "token" => "access-token",
        "refresh_token" => "refresh-token",
        "expires_at" => 1_772_691_847,
        "expires" => true,
        "scope" => TOKEN_SCOPE
      },
      strategy.credentials
    )
    assert_equal payload, strategy.extra["raw_info"]
    assert_equal "header.payload.signature", strategy.extra["id_token"]
    assert_equal(
      {
        "iss" => "https://accounts.google.com",
        "aud" => "client-id",
        "sub" => "123456789012345678901",
        "email" => "sample@example.test",
        "email_verified" => true,
        "name" => "Sample Person",
        "picture" => "https://lh3.googleusercontent.com/example-photo=s96-c",
        "given_name" => "Sample",
        "iat" => 1_772_689_518,
        "exp" => 1_772_693_118
      },
      strategy.extra["id_info"]
    )
  end

  def test_info_hides_unverified_email
    strategy = build_strategy
    payload = {
      "sub" => "123456789012345678901",
      "name" => "Sample Person",
      "email" => "sample@example.test",
      "email_verified" => false
    }

    strategy.instance_variable_set(:@raw_info, payload)

    refute strategy.info.key?(:email)
    assert_equal "sample@example.test", strategy.info[:unverified_email]
  end

  def test_callback_url_prefers_configured_value
    strategy = build_strategy
    callback = "https://example.test/auth/google2/callback"
    strategy.options[:callback_url] = callback

    assert_equal callback, strategy.callback_url
  end

  def test_request_phase_redirects_to_google_with_expected_params
    previous_request_validation_phase = OmniAuth.config.request_validation_phase
    OmniAuth.config.request_validation_phase = nil

    app = ->(_env) { [404, {"Content-Type" => "text/plain"}, ["not found"]] }
    strategy = OmniAuth::Strategies::Google2.new(app, "client-id", "client-secret")
    env = Rack::MockRequest.env_for("/auth/google2", method: "POST")
    env["rack.session"] = {}

    status, headers, = strategy.call(env)

    assert_equal 302, status
    location = URI.parse(headers["Location"])
    params = URI.decode_www_form(location.query).to_h

    assert_equal "accounts.google.com", location.host
    assert_equal "client-id", params.fetch("client_id")
    assert_equal "openid email profile", params.fetch("scope")
    assert_equal "offline", params.fetch("access_type")
  ensure
    OmniAuth.config.request_validation_phase = previous_request_validation_phase
  end

  def test_request_phase_preserves_prompt_hd_and_login_hint_options
    strategy = build_strategy
    request = Rack::Request.new(
      Rack::MockRequest.env_for(
        "/auth/google2?prompt=consent%20select_account" \
        "&login_hint=sample%40example.test&hd=example.test&include_granted_scopes=true"
      )
    )
    strategy.define_singleton_method(:request) { request }
    strategy.define_singleton_method(:session) { {} }

    params = strategy.authorize_params

    assert_equal "consent select_account", params.fetch(:prompt)
    assert_equal "sample@example.test", params.fetch(:login_hint)
    assert_equal "example.test", params.fetch(:hd)
    assert_equal "true", params.fetch(:include_granted_scopes)
  end

  def test_query_string_is_ignored_during_callback_request
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for("/auth/google2/callback?code=abc&state=xyz"))
    strategy.define_singleton_method(:request) { request }

    assert_equal "", strategy.query_string
  end

  class FakeAccessToken
    attr_reader :calls, :params, :token, :refresh_token, :expires_at

    def initialize(parsed_payload)
      @parsed_payload = parsed_payload
      @calls = []
      @params = {
        "scope" => TOKEN_SCOPE
      }
      @token = "access-token"
      @refresh_token = "refresh-token"
      @expires_at = 1_772_691_847
    end

    def get(path)
      @calls << {path: path}
      Struct.new(:parsed).new(@parsed_payload)
    end

    def [](key)
      {
        "id_token" => "header.payload.signature"
      }[key]
    end

    def expires?
      true
    end
  end
end
