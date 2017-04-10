require 'faraday'
require_relative '../error'

# @api private
module Faraday

  class Response::RaiseElvantoError < Response::Middleware

    CATEGORY_CODE_MAP = {
        50 => ElvantoAPI::Unauthorized,
        102 => ElvantoAPI::Unauthorized,
        250 => ElvantoAPI::BadRequest,
        404 => ElvantoAPI::NotFound,
        500 => ElvantoAPI::InternalError
    }

    HTTP_STATUS_CODES = {
        401 => ElvantoAPI::Unauthorized,
        400 => ElvantoAPI::BadRequest,
        404 => ElvantoAPI::NotFound,
        500 => ElvantoAPI::InternalError    
    }

    def on_complete(response)

      status_code = response[:status].to_i
      if response[:body] != nil && response[:body]['error']
        category_code = response[:body]['error']["code"]
      else
        category_code = nil
      end

      error_class = CATEGORY_CODE_MAP[category_code] || HTTP_STATUS_CODES[status_code]
      raise error_class.new(response[:body]) if error_class

    end

  end

end
