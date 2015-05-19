require "cgi"

module ElvantoAPI
  class Pager
    DEFAULT_SEP = /[&;] */n
    DEFAULT_LIMIT = 10

    include Enumerable

    attr_accessor :href
    attr_accessor :options

    # A pager for paginating through resource records.
    #
    # @param [String] uri the uri of the resource
    # @param [Hash] options
    # @option options [Integer] limit
    # @option options [Integer] offset
    # @option options [Integer] per an alias for the :limit option
    def initialize(href, options = {})
      @href = href
      @options = options
      @page = nil
      @resource_class = nil
    end

    def resource_class
      return @resource_class unless @resource_class.nil?
      load! unless @page
      @resource_class
    end

    def first
      load! unless @page
      if items.first.nil?
        nil
      else
        envelope = {
          :meta => @page[:meta],
          :links => @page[:links],
          @resource_class.collection_name.to_sym => [items.first]
        }
        resource_class.construct_from_response(envelope)
      end
    end

    def total
      load! unless @page
      @page[@resource_class.collection_name][:total]
    end

    def limit
      load! unless @page
      @page[@resource_class.collection_name][:per_page]
    end
    alias limit_value limit


    def items
      load! unless @page
      if @resource_class.nil?
        []
      else
        @page[@resource_class.collection_name][@resource_class.member_name]
      end
    end

    def current_page
      @page[@resource_class.collection_name][:page]
    end

    def num_pages
      num = total / limit
      num += 1 if total % limit > 0
      num
    end

    # @return [Array] Iterates through the current page of records.
    # @yield [record]
    def each
      return enum_for :each unless block_given?

      load! unless @page
      loop do
        items.each do |r|
          envelope = {
            @resource_class.member_name.to_sym => [r]
          }
          yield resource_class.construct_from_response(envelope)
        end
        raise StopIteration if last_page?
        self.next
      end
    end

    def last_page?
      current_page == num_pages
    end

    def first_page?
      current_page == 1
    end

    # @return [nil]
    # @see Resource.fetch_each
    # @yield [record]
    def fetch_each
      return enum_for :fetch_each unless block_given?
      begin
        each { |record| yield record }
      end while self.next
    end

    # @return [Array, nil] Refreshes the pager's collection of records with
    # the next page.
    def next
      load! unless @page

      new_options = @options.merge({page: current_page + 1})
      load_from @href, new_options unless last_page?
    end

    # @return [Array, nil] Refreshes the pager's collection of records with
    # the previous page.
    def prev
      load! unless @page
      new_options = @options.merge({page: current_page - 1})
      load_from @href, new_options unless first_page?
    end

    # @return [Array, nil] Refreshes the pager's collection of records with
    # the first page.
    def start
      load! unless @page
      new_options = @options.merge({page: 1})
      load_from @href, new_options
    end

    # @return [Array, nil] Load (or reload) the pager's collection from the
    # original, supplied options.
    def load!
      load_from @href, @options
    end
    alias reload load!

    # @return [Pager] Duplicates the pager, updating it with the options
    # supplied. Useful for resource scopes.
    # @see #initialize
    def paginate(options = {})
      dup.instance_eval {
        @page = nil
        @options.update options and self
      }
    end
    alias scoped paginate
    alias where paginate

    def all(options = {})
      paginate(options).to_a
    end


    private

    def load_from(uri, params)
      parsed_uri = URI.parse(uri)

      params ||= {}
      params = params.dup

      unless parsed_uri.query.nil?
        # The reason we don't use CGI::parse here is because
        # the ElvantoAPI api currently can't handle variable[]=value.
        # Faraday ends up encoding a simple query string like:
        # {"limit"=>["10"], "offset"=>["0"]}
        # to limit[]=10&offset[]=0 and that's cool, but
        # we have to make sure ElvantoAPI supports it.
        query_params = parse_query(parsed_uri.query)
        params.merge! query_params
        parsed_uri.query = nil
      end

      response = ElvantoAPI.post parsed_uri.to_s, params
      @page = ElvantoAPI::Utils.indifferent_read_access response.body

      #@href = @page[:meta][:href]
      # resource_class?
      hypermedia_key = (@page.keys.map{|k| k.to_sym } - [:generated_in, :status]).first
      
      unless hypermedia_key.nil?
        @resource_class = ("ElvantoAPI::" + ElvantoAPI::Utils.classify(hypermedia_key)).constantize
      end
      
      @page
    end


    # Stolen from Mongrel, with some small modifications:
    # Parses a query string by breaking it up at the '&'
    # and ';' characters. You can also use this to parse
    # cookies by changing the characters used in the second
    # parameter (which defaults to '&;').
    def parse_query(qs, d = nil)
      params = {}

      (qs || '').split(d ? /[#{d}] */n : DEFAULT_SEP).each do |p|
        k, v = p.split('=', 2).map { |x| CGI::unescape(x) }
        if (cur = params[k])
          if cur.class == Array
            params[k] << v
          else
            params[k] = [cur, v]
          end
        else
          params[k] = v
        end
      end

      params
    end
  end
end