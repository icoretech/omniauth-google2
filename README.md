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

Google OAuth app setup: [Google Cloud Console](https://console.cloud.google.com/apis/credentials)

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
  "uid": "123456789012345678901",
  "info": {
    "name": "Sample Person",
    "email": "sample@example.test",
    "unverified_email": "sample@example.test",
    "email_verified": true,
    "first_name": "Sample",
    "last_name": "Person",
    "image": "https://lh3.googleusercontent.com/example-photo=s96-c",
    "urls": {
      "google": "https://profiles.google.com/123456789012345678901"
    }
  },
  "credentials": {
    "token": "ya29.a0AfH6SM...",
    "refresh_token": "1//0gAbCdEf123456",
    "expires_at": 1772691847,
    "expires": true,
    "scope": "openid email profile"
  },
  "extra": {
    "id_token": "header.payload.signature",
    "id_info": {
      "iss": "https://accounts.google.com",
      "sub": "123456789012345678901"
    },
    "raw_info": {
      "sub": "123456789012345678901",
      "name": "Sample Person",
      "given_name": "Sample",
      "family_name": "Person",
      "picture": "https://lh3.googleusercontent.com/example-photo=s96-c",
      "email": "sample@example.test",
      "email_verified": true
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

## Release

Tag releases as `vX.Y.Z`; GitHub Actions publishes the gem to RubyGems.

## License

MIT
