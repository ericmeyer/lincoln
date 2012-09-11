module Lincoln
  module AttrIgnore
    def self.included(base) # :nodoc:
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)

      class << base
        alias_method :columns_with_attr_ignore, :columns
        alias_method :columns, :columns_without_attr_ignore

        alias_method_chain :default_select, :attr_ignore
      end
    end

    module ClassMethods
      # Attributes listed as ignore will be completely hidden from active record. They
      # will not show up in create, update, delete, or queries. Read and write methods
      # will not be generated as well.
      def attr_ignore(*attributes)
        write_inheritable_attribute(:attr_ignore, Set.new(attributes.map { |a| a.to_s }) + (ignore_attributes || []))
      end

      # Returns an array of all the attributes that have been specified as ignore.
      def ignore_attributes
        read_inheritable_attribute(:attr_ignore) || []
      end

      # Return the list of columns taking into account the attr_ignore attribute.
      def columns_without_attr_ignore
        unless defined?(@columns) && @columns
          @columns = columns_with_attr_ignore
          @columns.reject! { |column| ignore_attributes.include?(column.name) }
        end

        @columns
      end

      # Rails 2 ignores 'column' at :select time.
      def default_select_with_attr_ignore(qualified)
        default_select_without_attr_ignore(qualified) if ignore_attributes.blank?
        overwrite_val = columns.inject([]) do |accum, column|
          accum << (qualified ? "#{quoted_table_name}.#{connection.quote_column_name(column.name)}" : connection.quote_column_name(column.name))
          accum
        end.join(",")
      end

    end

    module InstanceMethods
    end
  end
end

ActiveRecord::Base.send(:include, Lincoln::AttrIgnore)
