module ElvantoAPI
  CLASS_MAPPING = {}

  module Utils

    

    def callable( callable_or_not )
      callable_or_not.respond_to?(:call) ? callable_or_not : lambda { callable_or_not }
    end

    def camelize(underscored_word)
      underscored_word.to_s.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    def classify(table_name)
      class_name = camelize singularize(table_name.to_s.sub(/.*\./, ''))
      class_name = CLASS_MAPPING[class_name] if CLASS_MAPPING.keys.include? class_name
      return class_name
    end

    def demodulize(class_name_in_module)
      class_name_in_module.to_s.sub(/^.*::/, '')
    end

    def pluralize(word)
      return "people" if word == "person"
      word.to_s.pluralize
    end

    def singularize(word)
      return "person" if word == "people"
      word.to_s.sub(/s$/, '').sub(/ie$/, 'y')
    end

    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr! '-', '_'
      word.downcase!
      word
    end

    def extract_href_from_object(object)
      object.respond_to?(:href) ? object.href : object
    end

    def indifferent_read_access(base = {})
      indifferent = Hash.new do |hash, key|
        hash[key.to_s] if key.is_a? Symbol
      end
      base.each_pair do |key, value|
        if value.is_a? Hash
          value = indifferent_read_access value
        elsif value.respond_to? :each
          if value.respond_to? :map!
            value.map! do |v|
              if v.is_a? Hash
                v = indifferent_read_access v
              end
              v
            end
          else
            value.map do |v|
              if v.is_a? Hash
                v = indifferent_read_access v
              end
              v
            end
          end
        end
        indifferent[key.to_s] = value
      end
      indifferent
    end

    def stringify_keys!(hash)
      hash.keys.each do |key|
        stringify_keys! hash[key] if hash[key].is_a? Hash
        hash[key.to_s] = hash.delete key if key.is_a? Symbol
      end
    end

    extend self
  end
end

