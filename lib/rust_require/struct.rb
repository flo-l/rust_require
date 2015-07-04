module Rust
  class Struct < FFI::Struct
    alias_method :old_get, :"[]"
    alias_method :old_set, :"[]="

    # TODO maybe type & bounds checking?

    def [](field)
      if field.respond_to? :to_sym
        field = field.to_sym
      elsif field.respond_to? :to_s
        field = field.to_s.to_sym
      end

      old_get(field)
    end

    def []=(field, obj)
      if field.respond_to? :to_sym
        field = field.to_sym
      elsif field.respond_to? :to_s
        field = field.to_s.to_sym
      end

      old_set(field, obj)
    end
  end
end
