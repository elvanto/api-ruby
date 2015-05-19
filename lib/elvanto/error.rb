module ElvantoAPI

  # Custom error class for rescuing from all API response-related ElvantoAPI errors
  class Error < ::StandardError
    attr_reader :body

    # @param [Hash] body The decoded json response body
    def initialize(body=nil)
      @body = Utils.indifferent_read_access(body)
      unless body.nil?
        super error_message
      end
    end


    # @return [Sting] The error message containting in body.
    def error_message
      set_attrs
      error = body.fetch('error', nil)
      if error
        error["message"]
      end
    end

    private
    def set_attrs
      error = body.fetch('error', nil)
      unless error.nil?
        error.keys.each do |name|
          self.class.instance_eval {
            define_method(name) { error[name] } # Get.
            define_method("#{name}?") { !!error[name] } # Present.
          }
        end
      end
    end
  end

  # General error class for non API response exceptions
  class StandardError < Error
    attr_reader :message
    alias :error_message :message

    # @param [String, nil] message a description of the exception
    def initialize(message = nil)
      @message = message
      super(message)
    end
  end

  # Raised when ElvantoAPI returns 50 or 102 error codes
  class Unauthorized < Error; end

  # Raised when ElvantoAPI returns a 250 error code
  class BadRequest < Error; end

  # Raised when ElvantoAPI returns a 404 error code
  class NotFound < Error; end

  # Raised when ElvantoAPI returns a 500 error code
  class InternalError < Error; end



end
