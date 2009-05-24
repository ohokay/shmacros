module Shmacros
  module Units
    ##
    #  Asserts that model has accept_nested_attribtues_for defined for specific models.
    #
    #    should_accept_nested_attributes_for :foo, :bar 
    #
    def should_accept_nested_attributes_for(*attr_names)
      klass = self.name.gsub(/Test$/, '').constantize

      context "#{klass}" do
        attr_names.each do |association_name|
          should "accept nested attrs for #{association_name}" do
            meth = "#{association_name}_attributes="
            assert  ([meth,meth.to_sym].any?{ |m| klass.instance_methods.include?(m) }),
                    "#{klass} does not accept nested attributes for #{association_name}"
          end
        end
      end
    end
    
    ##
    #  Asserts that model has act_as_taggable_on defined for certain categories.
    #
    #    should_act_as_taggable_on :category_name
    #    (default :category_name is :tags)
    #
    def should_act_as_taggable_on(category = :tags)
      klass = self.name.gsub(/Test$/, '').constantize

      should "include ActAsTaggableOn #{':' + category.to_s} methods" do
        assert klass.extended_by.include?(ActiveRecord::Acts::TaggableOn::ClassMethods)
        assert klass.extended_by.include?(ActiveRecord::Acts::TaggableOn::SingletonMethods)
        assert klass.include?(ActiveRecord::Acts::TaggableOn::InstanceMethods)
      end

      should_have_many :taggings, category
    end
    
    ##
    #  Asserts that model klass is_a?(Foo) or is_a?(Bar)
    #
    #    should_be Foo, Bar
    #
    def should_be(*ancestors)
      klass = self.name.gsub(/Test$/, '').constantize

      context "#{klass}" do
        ancestors.each do |ancestor|
          should "be #{ancestor}" do
            assert  klass.new.is_a?(ancestor),
                    "#{klass} is not #{ancestor}"
          end
        end
      end
    end
  
    ##
    #  Asserts that model defines callback for a certain method.
    #
    #    should_callback :foo, :after_save
    #    should_callback :bar, :baz, :before_save
    #
    def should_callback(*meths)
      if meths.size < 2
        raise(RuntimeError, "Expecting legal callback type as last argument.")
      end
    
      klass = self.name.gsub(/Test$/, '').constantize
      callback_type = meths.delete(meths.last).to_s
        
      meths.each do |meth|
        have_certain_callback = "call ##{meth} #{callback_type.to_s.gsub(/_/, ' ')}"
        should have_certain_callback do
          existing_callbacks = klass.send(callback_type)
          result = existing_callbacks.detect { |callback| callback.method == meth.to_sym }
          assert_not_nil result, "##{meth} is not called #{callback_type.to_s.gsub(/_/, ' ')}"
        end
      end
    end
  
    ##
    #  Asserts that model defines delegation for certain methods.
    #
    #    should_delegate :foo, :bar, :to => :eslewhere
    #
    def should_delegate(*methods)
      require 'mocha'
      
      klass = self.name.gsub(/Test$/, '').constantize
    
      options = methods.pop
      unless options.is_a?(Hash) && client = options[:to]
        raise ArgumentError, "Delegation needs a target. Supply an options hash with a :to key as the last argument (e.g. delegate :hello, :to => :greeter)."
      end
    
      if options[:prefix] == true && options[:to].to_s =~ /^[^a-z_]/
        raise ArgumentError, "Can only automatically set the delegation prefix when delegating to a method."
      end
    
      prefix = options[:prefix] && "#{options[:prefix] == true ? client : options[:prefix]}_"
    
      context "#{klass}" do
        methods.each do |method|
          should "delegate #{method} to #{client}" do
            method_name = "#{prefix}#{method}"
            obj = klass.new
            assert obj.respond_to?(method), "Method #{method} is not delegated."
            obj.send(client).expects(method_name).once
            obj.send(method)
          end
        end
      end
    end

    ##
    #  Asserts that model validates an associated model
    #
    #    should_validate_associated :foo, :bar
    #
    def should_validate_associated(*associations)
      klass = self.name.gsub(/Test$/, '').constantize
      associations.each do |association|
        should "validate associated #{association}" do
          assert klass.new.respond_to?("validate_associated_records_for_#{association}")
        end
      end
    end
  end
end

class ActiveSupport::TestCase
  extend Shmacros::Units
end