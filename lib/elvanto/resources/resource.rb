require File.expand_path('../../pager', __FILE__)
require File.expand_path('../../utils', __FILE__)
require 'addressable/template'

module ElvantoAPI

  module Resource


    attr_accessor :attributes

    # @params [Hash] attributes List of  object's attributes
    def initialize(attributes = {})
      @attributes = Utils.indifferent_read_access attributes
    end

    # @return [Object] New copy of the object with updated attributes
    def reload
      self.class.find({id: id})
    end

    # @params [Symbol] method The name of the method to call
    # @params [Hash] options The parameters to pass to the method.
    # @return [Object] The response from the API method.  
    def query_member(method, options={})
      self.class.query_member(method, options.merge({id: id}))
    end
    
    def method_missing(method, *args, &block)
      if @attributes.has_key?(method.to_s)
        return @attributes[method.to_s]
      end

      super method, *args, &block
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def resource_name
        Utils.demodulize name
      end

      def resource_class
        name.constantize
      end

      def collection_name
        Utils.pluralize Utils.underscore(resource_name)
      end

      def collection_path
        collection_name
      end

      alias_method :href, :collection_path

      def member_name
        Utils.underscore resource_name
      end

      # @param [Symbol] payload Body of the API response
      # @return [Object] Instance of the class specified in body
      def construct_from_response(payload)

        payload = ElvantoAPI::Utils.indifferent_read_access payload
        # the remaining keys here are just hypermedia resources
        payload.slice!(member_name)

        instance = nil
        
        payload.each do |key, value|
          if value.class == Hash
            resource_body = value
          else
            resource_body = value.first
          end
          # > Singular resources are represented as JSON objects. However,
          # they are still wrapped inside an array:
          #resource_body = value.first
          cls = ("ElvantoAPI::" + ElvantoAPI::Utils.classify(key)).constantize
          instance = cls.new resource_body
        end
        instance
        
      end

      # @param [Symbol] method The name of the method to call
      # @return [Boolean] True if API method returns a single object, otherwise false
      def member_method? method
        return unless defined? resource_class::MEMBER_METHODS
        resource_class::MEMBER_METHODS.keys.include? method
      end

      # @param [Symbol] method The name of the method to call
      # @return [Boolean] True if API method returns a set of objects, otherwise false
      def collection_method? method
        return unless defined? resource_class::COLLECTION_METHODS
        resource_class::COLLECTION_METHODS.keys.include? method
      end

      def method_missing(method, *args, &block)
        if member_method? method
          query_member(resource_class::MEMBER_METHODS[method], *args)
        elsif collection_method? method
          query_collection(resource_class::COLLECTION_METHODS[method], *args)
        else
          super method, *args, &block
        end
      end

      def def_instance_methods instance_methods={}
        instance_methods.each do |key, value|
          define_method(key) do |options={}|
            self.query_member(value, options)
          end
        end
      end

      # @params [Symbol] method The name of the method to call
      # @params [Hash] options The parameters to pass to the method.
      # @return [Object] The response from the API method.
      def query_member(method, options={})
        uri = href + "/" + method.to_s
        response = ElvantoAPI.post uri, options
        construct_from_response response.body         
      end

      # @params [Symbol] method The name of the method to call
      # @params [Hash] options The parameters to pass to the method.
      # @return [Array] The response from the API method.
      def query_collection(method, options={})
        uri = href + "/" + method.to_s
        pager = ElvantoAPI::Pager.new uri, options
        pager.to_a
      end

    end

  end
end
