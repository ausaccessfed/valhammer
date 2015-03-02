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
      v.is_a?(validation_impl(kind)) && (opts.nil? || v.options == opts) &&
        v.attributes.map(&:to_s) == [field.to_s]
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
    it { is_expected.not_to include(a_validator_for(:injected, :presence)) }
  end

  context 'with a non-nullable boolean' do
    let(:opts) { { in: [false, true], allow_nil: false } }

    it { is_expected.to include(a_validator_for(:injected, :inclusion, opts)) }
  end

  context 'with a nullable boolean' do
    subject { Capability.validators }
    let(:opts) { { in: [false, true], allow_nil: true } }

    it { is_expected.to include(a_validator_for(:core, :inclusion, opts)) }
  end

  context 'with a non-nullable association' do
    it { is_expected.to include(a_validator_for(:organisation, :presence)) }

    it 'excludes numericality validator' do
      expect(subject)
        .not_to include(a_validator_for(:organisation, :numericality))
    end

    it 'excludes validators on the foreign key' do
      expect(subject)
        .not_to include(a_validator_for(:organisation_id, :presence))
      expect(subject)
        .not_to include(a_validator_for(:organisation_id, :numericality))
    end
  end

  context 'with a nullable association' do
    subject { Capability.validators }

    it { is_expected.not_to include(a_validator_for(:organisation, :presence)) }

    it 'excludes validators on the foreign key' do
      expect(subject)
        .not_to include(a_validator_for(:organisation_id, :presence))
      expect(subject)
        .not_to include(a_validator_for(:organisation_id, :numericality))
    end
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

        belongs_to :organisation

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
          .and not_include(a_validator_for(:organisation, :presence))
      end
    end

    context ':inclusion' do
      let(:disabled_validator) { :inclusion }

      it 'excludes the inclusion validator' do
        expect(subject)
          .not_to include(a_validator_for(:injected, :inclusion))
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

  context 'sanity check' do
    around do |example|
      ActiveRecord::Base.transaction do
        example.run
        fail(ActiveRecord::Rollback)
      end
    end

    let(:organisation) do
      Organisation.create!(name: 'Enhanced Collaborative Methodologies Pty Ltd',
                           country: 'Australia', city: 'Brisbane')
    end

    context Resource do
      subject do
        Resource.new(name: 'Orson Orchestrator', identifier: 'orson',
                     mail: 'orson@synergize.example.com',
                     description: 'A dedicated but indifferent resource',
                     gpa: 3.5, injected: false, organisation: organisation)
      end

      it { is_expected.to be_valid }
    end

    context Capability do
      subject do
        Capability.create!(organisation: organisation, core: true,
                           name: 'Project Management')
      end

      it { is_expected.to be_valid }
    end
  end
end
