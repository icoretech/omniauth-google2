# frozen_string_literal: true

require 'jwt'
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    # OmniAuth strategy for Google OAuth2/OpenID Connect.
    class Google2 < OmniAuth::Strategies::OAuth2
      BASE_SCOPE_URL = 'https://www.googleapis.com/auth/'
      BASE_SCOPES = %w[openid email profile].freeze
      DEFAULT_SCOPE = 'openid email profile'
      USER_INFO_URL = 'https://openidconnect.googleapis.com/v1/userinfo'

      option :name, 'google2'
      option :authorize_options,
             %i[scope state access_type include_granted_scopes prompt login_hint hd redirect_uri nonce]
      option :scope, DEFAULT_SCOPE
      option :skip_jwt, false

      option :client_options,
             site: 'https://openidconnect.googleapis.com',
             authorize_url: 'https://accounts.google.com/o/oauth2/v2/auth',
             token_url: 'https://oauth2.googleapis.com/token',
             connection_opts: {
               headers: {
                 user_agent: 'icoretech-omniauth-google2 gem',
                 accept: 'application/json',
                 content_type: 'application/json'
               }
             }

      uid { raw_info['sub'] || raw_info['id'].to_s }

      info do
        {
          name: raw_info['name'],
          email: raw_info['email_verified'] ? raw_info['email'] : nil,
          unverified_email: raw_info['email'],
          email_verified: raw_info['email_verified'],
          first_name: raw_info['given_name'],
          last_name: raw_info['family_name'],
          image: raw_info['picture'],
          urls: raw_info['profile'] ? { google: raw_info['profile'] } : nil
        }.compact
      end

      credentials do
        {
          'token' => access_token.token,
          'refresh_token' => access_token.refresh_token,
          'expires_at' => access_token.expires_at,
          'expires' => access_token.expires?,
          'scope' => token_scope
        }.compact
      end

      extra do
        data = { 'raw_info' => raw_info }
        id_token = access_token['id_token']
        return data if blank?(id_token)

        data['id_token'] = id_token
        decoded = decode_id_token(id_token)
        data['id_info'] = decoded if decoded
        data
      end

      def authorize_params
        super.tap do |params|
          params[:scope] = normalize_scope(params[:scope] || options[:scope])
          params[:access_type] ||= 'offline'
          params[:include_granted_scopes] = 'true' if params[:include_granted_scopes] == true
          session['omniauth.state'] = params[:state] if params[:state]
        end
      end

      def raw_info
        @raw_info ||= access_token.get(USER_INFO_URL).parsed
      end

      # Ensure token exchange uses a stable callback URI that matches provider config.
      def callback_url
        options[:callback_url] || options[:redirect_uri] || super
      end

      # Prevent authorization response params from being appended to redirect_uri.
      def query_string
        return '' if request.params['code']

        super
      end

      private

      def normalize_scope(raw_scope)
        raw_scope.to_s.split(/[\s,]+/).reject(&:empty?).map do |scope|
          scope.start_with?('https://') || BASE_SCOPES.include?(scope) ? scope : "#{BASE_SCOPE_URL}#{scope}"
        end.join(' ')
      end

      def token_scope
        access_token.params['scope'] || access_token['scope']
      end

      def decode_id_token(token)
        return nil if options[:skip_jwt]

        payload, = JWT.decode(token, nil, false)
        payload
      rescue JWT::DecodeError
        nil
      end

      def blank?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end
    end

    GoogleOauth2 = Google2
  end
end

OmniAuth.config.add_camelization 'google2', 'Google2'
