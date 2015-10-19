module Valhammer
  module Validations
    VALHAMMER_DEFAULT_OPTS = { presence: true, uniqueness: true,
                               numericality: true, length: true,
                               inclusion: true }.freeze

    VALHAMMER_EXCLUDED_FIELDS = %w(created_at updated_at)

    private_constant :VALHAMMER_DEFAULT_OPTS, :VALHAMMER_EXCLUDED_FIELDS

    def valhammer(opts = {})
      @valhammer_indexes = connection.indexes(table_name)
      opts = VALHAMMER_DEFAULT_OPTS.merge(opts)
      columns_hash.each do |name, column|
        valhammer_validate(name, column, opts)
      end
    end

    private

    def valhammer_validate(name, column, opts)
      return if valhammer_exclude?(name)

      assoc_name = valhammer_assoc_name(name)
      if assoc_name.nil?
        validations = valhammer_validations(column, opts)
        validates(name, validations) unless validations.empty?
        return
      end

      return if column.null || !opts[:presence]
      validates(assoc_name, presence: true)
    end

    def valhammer_validations(column, opts)
      logger.debug("Valhammer generating options for #{valhammer_info(column)}")

      validations = {}
      valhammer_presence(validations, column, opts)
      valhammer_inclusion(validations, column, opts)
      valhammer_unique(validations, column, opts)
      valhammer_numeric(validations, column, opts)
      valhammer_length(validations, column, opts)

      logger.debug("Valhammer options for #{valhammer_log_key(column)} " \
                   "are: #{validations.inspect}")
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

      validations[:uniqueness] = valhammer_unique_opts(scope)
    end

    def valhammer_unique_opts(scope)
      nullable = scope.select { |c| columns_hash[c].null }

      opts = { allow_nil: true }
      opts[:scope] = scope if scope.any?
      opts[:if] = -> { nullable.all? { |c| send(c) } } if nullable.any?
      opts
    end

    def valhammer_numeric(validations, column, opts)
      return unless opts[:numericality]

      return if defined_enums.key?(column.name)

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
  end
end
