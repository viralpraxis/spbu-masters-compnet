require 'pry'
require "json"
require "securerandom"

require_relative "lib/handlers"

class ProductsStore
  PICTURE_FILENAME_GENERATOR = SecureRandom.method(:uuid)
  private_constant :PICTURE_FILENAME_GENERATOR

  def self.call(env)
    new(env).call
  end

  def initialize(env)
    @env = env
  end

  def call
    handle_failures do
      if match_route?(http_method: :get, path: "/api/products")
        Handlers.list_products
      elsif match_route?(http_method: :post, path: "/api/products")
        Handlers.create_product(JSON.parse(request_body))
      elsif match_route?(http_method: :get, path: %r{\A/api/products/(\d+)\z})
        matcher = %r{\A/api/products/(\d+)\z}.match(request.path)
        Handlers.fetch_product(id: matcher[1].to_i)
      elsif match_route?(http_method: :patch, path: %r{\A/api/products/(\d+)\z})
        matcher = %r{\A/api/products/(\d+)\z}.match(request.path)
        Handlers.update_product(id: matcher[1].to_i, data: JSON.parse(request_body))
      elsif match_route?(http_method: :delete, path: %r{\A/api/products/(\d+)\z})
        matcher = %r{\A/api/products/(\d+)\z}.match(request.path)
        Handlers.delete_product(id: matcher[1].to_i)
      elsif match_route?(http_method: :post, path: "/api/pictures")
        Handlers.create_picture(filename: parse_http_content_disposition_header || PICTURE_FILENAME_GENERATOR.call, data: request_body)
      else
        [404, {}, []]
      end
    end
  end

  private

    attr_reader :env

    def match_route?(http_method:, path:)
      return false unless request.public_send("#{http_method}?")

      if path.is_a?(String)
        request.path == path
      elsif path.is_a?(Regexp)
        path.match? request.path
      else
        raise ArgumentError, "Unexpected matching path class: #{path.class}"
      end
    end

    def parse_http_content_disposition_header
      request.get_header("HTTP_CONTENT_DISPOSITION")&.match(/filename=(\"?)(.+)\1/)&.[](2)
    end

    def handle_failures
      yield
    rescue StandardError => e
      [500, { "content-type" => "application/json" }, [JSON.dump({ error: e.message })]]
    end

    def request_body
      @request_body ||= request.body.read
    end

    def request
      @request ||= Rack::Request.new(env)
    end
end

run ProductsStore
