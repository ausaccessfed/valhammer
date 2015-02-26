module Valhammer
  module Validations
    def valhammer
      @valhammer_indexes ||= connection.indexes(table_name)

      columns_hash.each do |name, column|
        next if name == primary_key

        opts = valhammer_opts(column)
        validates(name, opts) unless opts.empty?
      end
    end

    private

    def valhammer_opts(column)
      logger.debug("Valhammer generating options for #{valhammer_info(column)}")
      opts = {}
      valhammer_presence(opts, column)
      valhammer_unique(opts, column)
      valhammer_numeric(opts, column)
      valhammer_length(opts, column)
      logger.debug("Valhammer options for #{valhammer_log_key(column)} " \
                   "are: #{opts.inspect}")
      opts
    end

    def valhammer_presence(opts, column)
      opts[:presence] = true unless column.null
    end

    def valhammer_unique(opts, column)
      @valhammer_indexes.any? do |i|
        opts[:uniqueness] = true if i.unique && i.columns.last == column.name
      end
    end

    def valhammer_numeric(opts, column)
      case column.type
      when :integer
        opts[:numericality] = { only_integer: true }
      when :decimal
        opts[:numericality] = { only_integer: false }
      end
    end

    def valhammer_length(opts, column)
      return unless column.type == :string && column.limit

      opts[:length] = { maximum: column.limit }
    end

    def valhammer_log_key(column)
      "`#{table_name}`.`#{column.name}`"
    end

    def valhammer_info(column)
      "#{valhammer_log_key(column)} (type=:#{column.type} " \
        "null=#{column.null || 'false'} limit=#{column.limit || 'nil'})"
    end
  end
end
