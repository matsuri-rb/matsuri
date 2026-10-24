# Vendored replacements for the ActiveSupport core_ext methods matsuri
# depends on. These are monkeypatches rather than refinements because
# definition files in downstream matsuri repos evaluate inside this
# process and call these methods ambiently; refinements would not reach
# them.

module Matsuri
  module CoreExt
    module_function

    def deep_transform_keys(object, &block)
      case object
      when Hash  then object.each_with_object({}) { |(k, v), h| h[yield(k)] = deep_transform_keys(v, &block) }
      when Array then object.map { |e| deep_transform_keys(e, &block) }
      else object
      end
    end
  end
end

class Hash
  def symbolize_keys
    transform_keys { |key| key.to_sym rescue key }
  end

  def stringify_keys
    transform_keys(&:to_s)
  end

  def deep_symbolize_keys
    deep_transform_keys { |key| key.to_sym rescue key }
  end

  def deep_stringify_keys
    deep_transform_keys(&:to_s)
  end

  def deep_transform_keys(&block)
    Matsuri::CoreExt.deep_transform_keys(self, &block)
  end
end

class Object
  def try(method_name = nil, *args, &block)
    if method_name.nil? && block
      block.arity.zero? ? instance_eval(&block) : yield(self)
    elsif respond_to?(method_name)
      public_send(method_name, *args, &block)
    end
  end

  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  def present?
    !blank?
  end

  def presence
    self if present?
  end
end

class NilClass
  def try(*)
    nil
  end
end

class String
  BLANK_RE = /\A[[:space:]]*\z/

  def blank?
    empty? || BLANK_RE.match?(self)
  end

  def camelize
    sub(/^[a-z\d]*/) { |match| match.capitalize }
      .gsub(%r{(?:_|(/))([a-z\d]*)}i) { "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }
      .gsub('/', '::')
  end
end

class Class
  def class_attribute(*names)
    names.each do |name|
      ivar = :"@#{name}"

      define_singleton_method(name) do
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        elsif superclass.respond_to?(name)
          superclass.public_send(name)
        end
      end

      define_singleton_method("#{name}=") do |value|
        instance_variable_set(ivar, value)
      end

      define_method(name) { self.class.public_send(name) }
    end
  end
end
