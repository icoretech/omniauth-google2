# OmniAuth Google2 Strategy

[![Test](https://github.com/icoretech/omniauth-google2/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/icoretech/omniauth-google2/actions/workflows/test.yml?query=branch%3Amain)
[![Gem Version](https://img.shields.io/gem/v/omniauth-google2.svg)](https://rubygems.org/gems/omniauth-google2)

`omniauth-google2` provides a Google OAuth2/OpenID Connect strategy for OmniAuth.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-google2'
```

Then run:

```bash
bundle install
```

## Usage

Configure OmniAuth in your Rack/Rails app:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google2,
           ENV.fetch('GOOGLE_CLIENT_ID'),
           ENV.fetch('GOOGLE_CLIENT_SECRET')
end
```

Compatibility alias is available, so you can keep existing callback paths using `google_oauth2`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch('GOOGLE_CLIENT_ID'),
           ENV.fetch('GOOGLE_CLIENT_SECRET')
end
```

## Provider App Setup

- Google Cloud Console: <https://console.cloud.google.com/apis/credentials>
- Register callback URL (example): `https://your-app.example.com/auth/google_oauth2/callback`

## Options

Supported request options include:
- `scope` (default: `openid email profile`)
- `access_type` (default: `offline`)
- `include_granted_scopes`
- `prompt`
- `login_hint`
- `hd`
- `redirect_uri`
- `nonce`

Scopes are normalized so short names like `email profile` are converted to Google OAuth scope URLs when required.

## Auth Hash

Example payload from `request.env['omniauth.auth']` (realistic shape, anonymized):

```json
{
  "uid": "111111111111111111111",
  "info": {
    "name": "sample-user",
    "email": "sample@gmail.com",
    "unverified_email": "sample@gmail.com",
    "email_verified": true,
    "first_name": "sample-user",
    "image": "https://lh3.googleusercontent.com/a/example-avatar=s96-c"
  },
  "credentials": {
    "token": "ya29.a0AfH6SM...",
    "refresh_token": "1//0gAbCdEf123456",
    "expires_at": 1772691847,
    "expires": true,
    "scope": "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email openid"
  },
  "extra": {
    "raw_info": {
      "sub": "111111111111111111111",
      "name": "sample-user",
      "given_name": "sample-user",
      "picture": "https://lh3.googleusercontent.com/a/example-avatar=s96-c",
      "email": "sample@gmail.com",
      "email_verified": true
    },
    "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6I...redacted...",
    "id_info": {
      "iss": "https://accounts.google.com",
      "aud": "1012003270838.apps.googleusercontent.com",
      "sub": "111111111111111111111",
      "email": "sample@gmail.com",
      "email_verified": true,
      "name": "sample-user",
      "picture": "https://lh3.googleusercontent.com/a/example-avatar=s96-c",
      "given_name": "sample-user",
      "iat": 1772689518,
      "exp": 1772693118
    }
  }
}
```

## Development

```bash
bundle install
bundle exec rake
```

Run Rails integration tests with an explicit Rails version:

```bash
RAILS_VERSION='~> 8.1.0' bundle install
RAILS_VERSION='~> 8.1.0' bundle exec rake test_rails_integration
```

## Compatibility

- Ruby: `>= 3.2` (tested on `3.2`, `3.3`, `3.4`, `4.0`)
- `omniauth-oauth2`: `>= 1.8`, `< 1.9`
- Rails integration lanes: `~> 7.1.0`, `~> 7.2.0`, `~> 8.0.0`, `~> 8.1.0`

## Endpoints

This gem uses Google OpenID Connect discovery endpoints:
- `https://accounts.google.com/o/oauth2/v2/auth`
- `https://oauth2.googleapis.com/token`
- `https://openidconnect.googleapis.com/v1/userinfo`

## Smoke Variants

After a baseline smoke succeeds, run these extra request-phase variants:
- `?prompt=consent select_account`
- `?login_hint=user@example.com`
- `?hd=example.com`
- `?include_granted_scopes=true`

These verify option pass-through and help catch provider-side UX or consent regressions.

## Test Structure

- `test/omniauth_google2_test.rb`: strategy/unit behavior
- `test/rails_integration_test.rb`: full Rack/Rails request+callback flow
- `test/test_helper.rb`: shared test bootstrap

## Release

Tag releases as `vX.Y.Z`; GitHub Actions publishes the gem to RubyGems.

## License

MIT
