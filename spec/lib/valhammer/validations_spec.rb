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

  RSpec::Matchers.define_negated_matcher :not_include, :include

  subject { Resource.validators }

  context 'with non-nullable columns' do
    it { is_expected.not_to include(a_validator_for(:id, :presence)) }
    it { is_expected.not_to include(a_validator_for(:created_at, :presence)) }
    it { is_expected.not_to include(a_validator_for(:updated_at, :presence)) }
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

  context 'with a composite unique index' do
    subject { Capability.validators }

    let(:opts) { { scope: ['organisation_id'], case_sensitive: true } }
    it { is_expected.to include(a_validator_for(:name, :uniqueness, opts)) }
  end

  context 'with duplicate unique indexes' do
    subject { Organisation.validators }

    it { is_expected.not_to include(a_validator_for(:name, :uniqueness)) }
    it { is_expected.not_to include(a_validator_for(:country, :uniqueness)) }
    it { is_expected.not_to include(a_validator_for(:city, :uniqueness)) }
  end

  context 'with an integer column' do
    context 'with allow_nil' do
      let(:opts) { { only_integer: true, allow_nil: true } }
      it { is_expected.to include(a_validator_for(:age, :numericality, opts)) }
    end
    context 'without allow_nil' do
      let(:opts) { { only_integer: true, allow_nil: false } }
      it 'sets allow_nil to false for socialness' do
        expect(subject)
          .to include(a_validator_for(:socialness, :numericality, opts))
      end
    end
  end

  context 'with a numeric column' do
    let(:opts) { { only_integer: false, allow_nil: false } }
    it { is_expected.to include(a_validator_for(:gpa, :numericality, opts)) }
  end

  context 'with a limited length string' do
    it { is_expected.to include(a_validator_for(:name, :length, maximum: 100)) }
  end

  context 'with disabled validations' do
    around do |example|
      old = ActiveRecord::Base.logger

      begin
        ActiveRecord::Base.logger = Logger.new('/dev/null')
        example.run
      ensure
        ActiveRecord::Base.logger = old
      end
    end

    let(:klass) do
      opts = { disabled_validator => false }
      Class.new(ActiveRecord::Base) do
        self.table_name = 'resources'
        valhammer(opts)
      end
    end

    subject { klass.validators }

    context ':presence' do
      let(:disabled_validator) { :presence }

      it 'excludes the presence validator' do
        expect(subject)
          .to not_include(a_validator_for(:name, :presence))
          .and not_include(a_validator_for(:mail, :presence))
          .and not_include(a_validator_for(:identifier, :presence))
          .and not_include(a_validator_for(:gpa, :presence))
      end
    end

    context ':uniqueness' do
      let(:disabled_validator) { :uniqueness }

      it 'excludes the uniqueness validator' do
        expect(subject)
          .not_to include(a_validator_for(:identifier, :uniqueness))
      end
    end

    context ':numericality' do
      let(:disabled_validator) { :numericality }

      it 'excludes the numericality validator' do
        expect(subject).to not_include(a_validator_for(:age, :numericality))
          .and not_include(a_validator_for(:gpa, :numericality))
      end
    end

    context ':length' do
      let(:disabled_validator) { :length }

      it 'excludes the length validator' do
        expect(subject).not_to include(a_validator_for(:name, :length))
      end
    end
  end
end
