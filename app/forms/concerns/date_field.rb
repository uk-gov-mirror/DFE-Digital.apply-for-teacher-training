module DateField
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Attributes

  end

  class_methods do
    def date_field(field)
      attribute("#{field}(3i)", :string)
      attribute("#{field}(2i)", :string)
      attribute("#{field}(1i)", :string)
      attr_accessor field

      define_method(field) do
        date = instance_variable_get("@#{field}")
        if date.present? && date.respond_to?(:day)
          write_attribute "#{field}(3i)", date.day
          write_attribute "#{field}(2i)", date.month
          write_attribute "#{field}(1i)", date.year
        end

        day, month, year = [ send("#{field}(3i)"), send("#{field}(2i)"), send("#{field}(1i)") ]

        begin
          instance_variable_set("@#{field}", Date.new(year.to_i, month.to_i, day.to_i))
        rescue ArgumentError
          instance_variable_set("@#{field}", Struct.new(:day, :month, :year).new(day, month, year))
        end
      end
    end
  end
end
