$:.unshift File.join(File.dirname(__FILE__), "elvanto", "resources")
$:.unshift File.join(File.dirname(__FILE__), "elvanto", "response")

require 'uri'
require 'elvanto/version' unless defined? ElvantoAPI::VERSION
require 'elvanto/client'
require 'elvanto/utils'
require 'elvanto/error'


module ElvantoAPI

  @config = {
      :scheme => 'https',
      :host => 'api.elvanto.com',
      :port => 443,
      :version => '1',
      :api_version => "/v1",
      :accept => "json"
  }

  @tokens = {}

  @hypermedia_registry = {}

  class << self

    attr_accessor :client
    attr_accessor :config
    attr_accessor :tokens


    # @params [Hash] options Connection configuration options
    # In order to authenticate with access token: options = {access_token: "access_token", ...}
    # In order to authenticate with API key: options = {api_key: "api_key", ...}
    def configure(options={})
      @config = @config.merge(options)
      @config[:access_token] ||= tokens[:access_token]
      @client = ElvantoAPI::Client.new(@config)
    end



    # @params [String] client_id The Client ID of your registered OAuth application.
    # @params [String] redirect_url The Redirect URI of your registered OAuth application.
    # @params [String] scope
    # @params [String] state Optional state data to be included in the URL.
    # @return [String] The authorization URL to which users of your application should be redirected.
    def authorize_url(client_id, redirect_uri, scope="AdministerAccount", state=nil)
      
      scope = scope.join(",") if scope.class == Array

      params = {type: "web_server", client_id: client_id, redirect_uri: redirect_uri, scope: scope}
      params[:state] = state if state

      uri = Addressable::URI.new({:host => config[:host],:scheme => config[:scheme], :path => "oauth",:query_values => params})
      return uri.to_s
    end

    # @params [String] client_id The Client ID of your registered OAuth application.
    # @param [String] client_secret The Client Secret of your registered OAuth application.
    # @param [String] code The unique OAuth code to be exchanged for an access token.
    # @param [String] redirect_url The Redirect URI of your registered OAuth application.
    # @return [Hash] The hash with keys 'access_token', 'expires_in', and 'refresh_token'
    def exchange_token(client_id, client_secret, code, redirect_uri)
      params = {grant_type: 'authorization_code', client_id: client_id, client_secret: client_secret, code: code, redirect_uri: redirect_uri}
      response = Faraday.new(client.url).post "oauth/token", params
      @tokens = JSON.parse(response.body, :symbolize_keys => true)
      return @tokens
    end

    # @param [String] refresh_token Was included when the original token was granted to automatically retrieve a new access token.
    # @return [Hash] The hash with keys 'access_token', 'expires_in', and 'refresh_token'
    def refresh_token(token=nil)
      token ||= tokens[:refresh_token]
      raise "Error refreshing token. There is no refresh token set on this object" unless token

      params = {grant_type: "refresh_token", refresh_token: token}
      response = Faraday.new(client.url).post "oauth/token", params
      @tokens = JSON.parse(response.body,:symbolize_keys => true)
      return @tokens
    end

    def post(href, options={})
      self.client.post href, options
    end

    # @param [String] enpoint The name of endpoint, for example: "people/getAll" or "groups/GetInfo"
    # @param [Hash] option List of parametrs
    # @result [Hash] Body of the API response
    def call(endpoint, options={})
      response = post endpoint, options
      return response.body
    end

  end

  configure
end

 # require all the elvanto resources.
 require_relative 'elvanto/resources'