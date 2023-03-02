# frozen_string_literal: true

class Storage
  @@backend = Hash.new
  @@sequences = Hash.new(0)

  @@scheme = {
    products: Struct.new(:id, :title, :price, :created_at, :picture_id, keyword_init: true),
    pictures: Struct.new(:id, :data, :filename, :created_at, keyword_init: true)
  }.freeze

  @@foreign_key_validations = {
    products: [
      %i[picture_id pictures]
    ]
  }

  class << self
    def insert(entity, payload)
      scheme = @@scheme[entity]
      @@backend[entity] ||= []

      payload.transform_keys!(&:to_sym)

      payload[:id] = (@@sequences[entity] += 1) if scheme.members.include?(:id)
      payload[:created_at] = Time.now.to_s if scheme.members.include?(:created_at)

      entry = scheme.new(payload.slice(*scheme.members))

      entry.tap { |e| @@backend[entity] << entry }
    end

    def list(entity)
      @@backend[entity] ||= []
      @@backend[entity].map(&:to_h)
    end

    def find_by(entity, attribute:, value:)
      @@backend[entity] ||= []
      @@backend[entity].find do |entry|
        entry.public_send(attribute) == value
      end
    end

    def update(entity, id:, data:)
      @@backend[entity] ||= []
      entry = find_by(entity, attribute: :id, value: id)
      data.transform_keys!(&:to_sym)
      return false unless entry
      return false unless validate_foreign_key_constraints(entity, data)

      data.each do |key, value|
        entry.public_send("#{key}=", value)
      end

      true
    end

    def delete(entity, id:)
      @@backend[entity] ||= []
      entry = find_by(entity, attribute: :id, value: id)
      return false unless entry

      !!@@backend[entity].delete(entry)
    end

    private

      def validate_foreign_key_constraints(entity, payload)
        @@foreign_key_validations[entity.to_sym].each do |fkv|
          value = payload[fkv[0]]&.to_s

          if (value&.size || 0) > 0 && !find_by(fkv[1], attribute: :id, value: payload[fkv[0]])
             return false if @@scheme[entity].members.map(&:to_sym).include? fkv[0].to_sym
          end
        end

        true
      end
  end
end
