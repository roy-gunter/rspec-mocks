require 'spec_helper'

module RSpec
  module Mocks
    describe "using a Partial Mock," do
      let(:object) { Object.new }

      it "names the class in the failure message" do
        object.should_receive(:foo)
        expect do
          object.rspec_verify
        end.to raise_error(RSpec::Mocks::MockExpectationError, /\(#<Object:.*>\).foo/)
      end

      it "names the class in the failure message when expectation is on class" do
        Object.should_receive(:foo)
        lambda do
          Object.rspec_verify
        end.should raise_error(RSpec::Mocks::MockExpectationError, /<Object \(class\)>/)
      end

      it "does not conflict with @options in the object" do
        object.instance_eval { @options = Object.new }
        object.should_receive(:blah)
        object.blah
      end

      it "should_not_receive mocks out the method" do
        object.should_not_receive(:fuhbar)
        expect {
          object.fuhbar
        }.to raise_error(
          RSpec::Mocks::MockExpectationError,
          /expected\: 0 times\n    received\: 1 time/
        )
      end

      it "should_not_receive returns a negative message expectation" do
        object.should_not_receive(:foobar).should be_kind_of(RSpec::Mocks::NegativeMessageExpectation)
      end

      it "should_receive mocks out the method" do
        object.should_receive(:foobar).with(:test_param).and_return(1)
        object.foobar(:test_param).should equal(1)
      end

      it "should_receive handles a hash" do
        object.should_receive(:foobar).with(:key => "value").and_return(1)
        object.foobar(:key => "value").should equal(1)
      end

      it "should_receive handles an inner hash" do
        hash = {:a => {:key => "value"}}
        object.should_receive(:foobar).with(:key => "value").and_return(1)
        object.foobar(hash[:a]).should equal(1)
      end

      it "should_receive returns a message expectation" do
        object.should_receive(:foobar).should be_kind_of(RSpec::Mocks::MessageExpectation)
        object.foobar
      end

      it "should_receive verifies method was called" do
        object.should_receive(:foobar).with(:test_param).and_return(1)
        lambda do
          object.rspec_verify
        end.should raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "should_receive also takes a String argument" do
        object.should_receive('foobar')
        object.foobar
      end

      it "should_not_receive also takes a String argument" do
        object.should_not_receive('foobar')
        lambda do
          object.foobar
        end.should raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "uses reports nil in the error message" do
        allow_message_expectations_on_nil

        _nil = nil
        _nil.should_receive(:foobar)
        expect {
          _nil.rspec_verify
        }.to raise_error(
          RSpec::Mocks::MockExpectationError,
          %Q|(nil).foobar(any args)\n    expected: 1 time\n    received: 0 times|
        )
      end

      it "includes the class name in the error when mocking a class method that is called an extra time with the wrong args" do
        klass = Class.new do
          def self.to_s
            "MyClass"
          end
        end

        klass.should_receive(:bar).with(1)
        klass.bar(1)

        expect {
          klass.bar(2)
        }.to raise_error(RSpec::Mocks::MockExpectationError, /MyClass/)
      end
    end

    describe "Partially mocking an object that defines ==, after another mock has been defined" do
      before(:each) do
        stub("existing mock", :foo => :foo)
      end

      let(:klass) do
        Class.new do
          attr_reader :val
          def initialize(val)
            @val = val
          end

          def ==(other)
            @val == other.val
          end
        end
      end

      it "does not raise an error when stubbing the object" do
        o = klass.new :foo
        expect { o.stub(:bar) }.not_to raise_error(NoMethodError)
      end
    end

    describe "Method visibility when using partial mocks" do
      let(:klass) do
        Class.new do
          def public_method
            private_method
            protected_method
          end
          protected
          def protected_method; end
          private
          def private_method; end
        end
      end

      let(:object) { klass.new }

      it 'keeps public methods public' do
        object.should_receive(:public_method)
        object.public_methods.should include_method(:public_method)
        object.public_method
      end

      it 'keeps private methods private' do
        object.should_receive(:private_method)
        object.private_methods.should include_method(:private_method)
        object.public_method
      end

      it 'keeps protected methods protected' do
        object.should_receive(:protected_method)
        object.protected_methods.should include_method(:protected_method)
        object.public_method
      end

    end
  end
end
