class DataSetDocumentation
  def self.for(klass)
    name = klass.name.demodulize.underscore

    spec = YAML.load_file(Rails.root.join("app/exports/#{name}.yml"))
    common_columns = load_common_columns
    custom_columns = spec['custom_columns']

    check_for_shadowed_columns(common_columns, custom_columns)

    used_common_columns = common_columns.slice(*spec['common_columns'])
    used_common_columns.merge(custom_columns || {})
  end

  def self.check_for_shadowed_columns(common_columns, custom_columns)
    if (custom_columns.keys.map(&:to_sym) & common_columns.keys.map(&:to_sym)).any?
      raise 'There are columns in the export documentation that shadow the shared common columns'
    end
  end

  def self.load_common_columns
    Dir[Rails.root.join('app/exports/common_columns/*')]
        .map { |file| YAML.load_file(file) }
        .reduce({}, :merge)
  end

  private_class_method :load_common_columns, :check_for_shadowed_columns
end
