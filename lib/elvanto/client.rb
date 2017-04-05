require 'logger'
require 'uri'
require 'faraday'
require 'faraday_middleware'
require 'elvanto/response/elvanto_exception_middleware'

module ElvantoAPI
  class Client

    DEFAULTS = {
      :scheme => 'http',
      :host => 'localhost',
      :api_version => nil,
      :port => 3000,
      :version => '1',
      :logging_level => 'WARN',
      :connection_timeout => 60,
      :read_timeout => 60,
      :logger => nil,
      :ssl_verify => false,
      :faraday_adapter => Faraday.default_adapter,
      :accept_type => 'application/json'
    }

    attr_reader :conn
    attr_accessor :access_token, :config

    def initialize(options={})
      @config = DEFAULTS.merge options
      build_conn
    end

    def build_conn
      if config[:logger]
        logger = config[:logger]
      else
        logger = Logger.new(STDOUT)
        logger.level = Logger.const_get(config[:logging_level].to_s)
      end

      Faraday::Response.register_middleware :handle_elvanto_errors => lambda { Faraday::Response::RaiseElvantoError }

      options = {
        :request => {
          :open_timeout => config[:connection_timeout],
          :timeout => config[:read_timeout]
        },
        :ssl => {
          :verify => @config[:ssl_verify] # Only set this to false for testing
        }
      }
      @conn = Faraday.new(url, options) do |cxn|
        cxn.request :json

        cxn.response :logger, logger
        cxn.response :handle_elvanto_errors
        cxn.response :json
        #cxn.response :raise_error # raise exceptions on 40x, 50x responses
        cxn.adapter config[:faraday_adapter]
      end
      conn.path_prefix = '/'
      conn.headers['User-Agent'] = "elvanto-ruby/" + config[:version]

      if config[:access_token]
        # Authenticating with OAuth
        conn.headers["Authorization"]  = "Bearer " + config[:access_token] 
      elsif config[:api_key]
        # Authenticating with an API key
        conn.basic_auth(config[:api_key], '')
      end

    end

    # Building the host url of the API Endpoint
    def url
      builder = (config[:scheme] == 'http') ? URI::HTTP : URI::HTTPS
      builder.build({:host => config[:host],:port => config[:port],:scheme => config[:scheme]})
    end

    def api_version
      return "" unless ElvantoAPI.config[:api_version] 
      ElvantoAPI.config[:api_version] + "/"
    end

    def post(href, options={})
      uri = api_version  + href + "." + config[:accept]
      conn.post uri, options
    end

    def get(href, options={})
      conn.get href, options
    end

  end
end
