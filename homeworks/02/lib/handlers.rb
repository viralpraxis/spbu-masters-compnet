# frozen_string_literal: true

require_relative "storage"

module Handlers
  module_function

  def list_products
    data = Storage.list(:products)

    render_json data: { products: data }
  end

  def create_product(data)
    data = Storage.insert(:products, data)

    render_json http_status: 201, data: { message: "Created" }
  end

  def fetch_product(id:)
    entity = Storage.find_by(:products, attribute: :id, value: id)&.to_h

    if entity
      render_json data: { product: entity }
    else
      render_http_not_found
    end
  end

  def update_product(id:, data:)
    if Storage.update(:products, id: id, data: data)
      render_http_no_content
    else
      render_http_not_found
    end
  end

  def delete_product(id:)
    if Storage.delete(:products, id: id)
      render_http_no_content
    else
      render_http_not_found
    end
  end

  def create_picture(filename:, data:)
    picture = Storage.insert(:pictures, { filename: filename, data: data })

    render_json http_status: 201, data: { picture: picture.to_h.slice(:id, :created_at, :filename) }
  end

  def render_http_not_found
    render_json http_status: 404, data: { message: "Not Found" }
  end

  def render_http_no_content
    [204, {}, []]
  end

  def render_json(http_status: 200, data: {})
    [http_status, { "content-type" => "application/json"}, [JSON.dump(data)]]
  end
end
