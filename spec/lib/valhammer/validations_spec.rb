RSpec.describe Valhammer::Validations do
  def validation_impl(kind)
    name = "#{kind.to_s.camelize}Validator"

    if ActiveRecord::Validations.const_defined?(name)
      ActiveRecord::Validations.const_get(name)
    else
      ActiveModel::Validations.const_get(name)
    end
  end

  RSpec::Matchers.define :a_validator_for do |field, kind, opts = nil|
    match do |v|
      v.is_a?(validation_impl(kind)) && v.attributes == [field.to_s] &&
        (opts.nil? || v.options == opts)
    end

    description do
      "a #{kind.inspect} validator for #{field.inspect}" \
        "#{opts && " with options: #{opts.inspect}"}"
    end
  end

  subject { Resource.validators }

  class Resource < ActiveRecord::Base
    valhammer
  end

  context 'with non-nullable columns' do
    it { is_expected.not_to include(a_validator_for(:id, :presence)) }
    it { is_expected.to include(a_validator_for(:name, :presence)) }
    it { is_expected.to include(a_validator_for(:mail, :presence)) }
    it { is_expected.to include(a_validator_for(:identifier, :presence)) }
    it { is_expected.not_to include(a_validator_for(:description, :presence)) }
    it { is_expected.to include(a_validator_for(:gpa, :presence)) }
  end

  context 'with a unique index' do
    it { is_expected.not_to include(a_validator_for(:id, :uniqueness)) }
    it { is_expected.to include(a_validator_for(:identifier, :uniqueness)) }
    it { is_expected.not_to include(a_validator_for(:mail, :uniqueness)) }
  end

  context 'with an integer column' do
    let(:opts) { { only_integer: true } }
    it { is_expected.to include(a_validator_for(:age, :numericality, opts)) }
  end

  context 'with a numeric column' do
    let(:opts) { { only_integer: false } }
    it { is_expected.to include(a_validator_for(:gpa, :numericality, opts)) }
  end

  context 'with a limited length string' do
    it { is_expected.to include(a_validator_for(:name, :length, maximum: 100)) }
  end
end
