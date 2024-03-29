module Valhammer
  module Validations
    class DisabledFieldConfig
      def self.perform(&bl)
        new.tap { |obj| obj.instance_eval(&bl) if block_given? }.to_opts
      end

      def initialize
        @disabled_validations = {}
      end

      ALL = %i(presence uniqueness inclusion length numericality).freeze

      def disable(opts)
        opts = { opts => ALL } if opts.is_a?(Symbol)

        opts.each do |k, v|
          @disabled_validations[k] ||= []
          @disabled_validations[k] += Array(v)
        end
      end

      def to_opts
        @disabled_validations.stringify_keys.transform_values do |v|
          Hash[v.zip(Array.new(v.length, false))]
        end
      end
    end

    VALHAMMER_EXCLUDED_FIELDS = %w(created_at updated_at).freeze

    private_constant :VALHAMMER_EXCLUDED_FIELDS, :DisabledFieldConfig

    def valhammer(&bl)
      @valhammer_indexes = connection.indexes(table_name)
      config = DisabledFieldConfig.perform(&bl)

      columns_hash.each do |name, column|
        valhammer_validate(name, column, config)
      end
    end

    private

    def valhammer_validate(name, column, config)
      return if valhammer_exclude?(name)

      assoc_name = valhammer_assoc_name(name)
      return valhammer_validate_assoc(assoc_name, column, config) if assoc_name

      opts = valhammer_field_config(config, name)
      validations = valhammer_validations(column, opts)
      validates(name, validations) unless validations.empty?
    end

    def valhammer_validate_assoc(assoc_name, column, config)
      opts = valhammer_field_config(config, assoc_name)
      return if column.null || !opts[:presence]
      validates(assoc_name, presence: true)
    end

    def valhammer_field_config(config, field)
      Hash.new(true).merge(config[field.to_s] || {})
    end

    def valhammer_validations(column, opts)
      validations = {}
      valhammer_presence(validations, column, opts)
      valhammer_inclusion(validations, column, opts)
      valhammer_unique(validations, column, opts)
      valhammer_numeric(validations, column, opts)
      valhammer_length(validations, column, opts)

      if Valhammer.config.verbose?
        logger.debug("Valhammer options for #{valhammer_log_key(column)} " \
                     "are: #{validations.inspect}")
      end
      validations
    end

    def valhammer_presence(validations, column, opts)
      return unless opts[:presence] && column.type != :boolean

      validations[:presence] = true unless column.null
    end

    def valhammer_inclusion(validations, column, opts)
      return unless opts[:inclusion] && column.type == :boolean

      validations[:inclusion] = { in: [false, true], allow_nil: column.null }
    end

    def valhammer_unique(validations, column, opts)
      return unless opts[:uniqueness]

      unique_keys = valhammer_unique_keys(column)
      return unless unique_keys.one?

      scope = unique_keys.first.columns[0..-2]
      validations[:uniqueness] = valhammer_unique_opts(column, scope)
    end

    def valhammer_unique_opts(column, scope)
      nullable = scope.select { |c| columns_hash[c].null }
      opts = { allow_nil: true,
               case_sensitive: case_sensitive?(column) }
      opts[:scope] = scope.map(&:to_sym) if scope.any?
      opts[:if] = -> { nullable.all? { |c| send(c) } } if nullable.any?
      opts
    end

    def valhammer_numeric(validations, column, opts)
      return if !opts[:numericality] || defined_enums.key?(column.name)

      case column.type
      when :integer
        validations[:numericality] = { only_integer: true,
                                       allow_nil: true }
      when :decimal
        validations[:numericality] = { only_integer: false,
                                       allow_nil: true }
      end
    end

    def valhammer_length(validations, column, opts)
      return unless opts[:length] && column.type == :string && column.limit
      validations[:length] = { maximum: column.limit }
    end

    def valhammer_log_key(column)
      "`#{table_name}`.`#{column.name}`"
    end

    def valhammer_info(column)
      "#{valhammer_log_key(column)} (type=:#{column.type} " \
        "null=#{column.null || 'false'} limit=#{column.limit || 'nil'})"
    end

    def valhammer_exclude?(field)
      field == primary_key || VALHAMMER_EXCLUDED_FIELDS.include?(field)
    end

    def valhammer_unique_keys(column)
      @valhammer_indexes.select do |i|
        i.unique && !i.where && i.columns.last == column.name
      end
    end

    def valhammer_assoc_name(field)
      reflect_on_all_associations(:belongs_to)
        .find { |a| a.foreign_key == field }.try(:name)
    end

    def case_sensitive?(column)
      return true unless column.respond_to?(:case_sensitive?)

      column.case_sensitive?
    end
  end
end
