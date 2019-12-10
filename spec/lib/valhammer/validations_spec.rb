RSpec.describe Valhammer::Validations do
  around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise(ActiveRecord::Rollback)
    end
  end

  def validation_impl(kind)
    name = "#{kind.to_s.camelize}Validator"

    if ActiveRecord::Validations.const_defined?(name)
      ActiveRecord::Validations.const_get(name)
    else
      ActiveModel::Validations.const_get(name)
    end
  end

  RSpec::Matchers.define :a_validator_for do |field, kind, opts = nil|
    include RSpec::Matchers::Composable

    match do |v|
      v.is_a?(validation_impl(kind)) &&
        (opts.nil? || values_match?(opts, v.options)) &&
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

    it 'creates a case insensitive validator' do
      opts = { case_sensitive: true, allow_nil: true }

      expect(subject)
        .to include(a_validator_for(:identifier, :uniqueness, opts))
    end
  end

  context 'with a partial unique index' do
    subject { Capability.validators }

    it { is_expected.not_to include(a_validator_for(:identifier, :uniqueness)) }
  end

  context 'with a composite unique index' do
    let(:opts) do
      { scope: [:organisation_id], case_sensitive: true, allow_nil: true }
    end

    it { is_expected.to include(a_validator_for(:name, :uniqueness, opts)) }
  end

  context 'with a composite unique index with nullable scope column' do
    subject { Capability.validators }

    let(:opts) do
      { scope: [:organisation_id], case_sensitive: true, allow_nil: true,
        if: an_instance_of(Proc) }
    end

    it { is_expected.to include(a_validator_for(:name, :uniqueness, opts)) }

    it 'skips validation when the nullable scope column is null' do
      o = Organisation.create!(country: 'Australia', city: 'Brisbane',
                               name: 'Test Organisation')

      attrs = { organisation_id: o.id, name: 'Software Development',
                identifier: SecureRandom.urlsafe_base64 }

      Capability.create!(attrs)

      attrs[:identifier] = SecureRandom.urlsafe_base64
      Capability.create!(attrs.merge(organisation_id: nil))

      attrs[:identifier] = SecureRandom.urlsafe_base64
      expect(Capability.new(attrs.merge(organisation_id: nil))).to be_valid
      expect(Capability.new(attrs)).not_to be_valid
    end
  end

  context 'with duplicate unique indexes' do
    subject { Organisation.validators }

    it { is_expected.not_to include(a_validator_for(:name, :uniqueness)) }
    it { is_expected.not_to include(a_validator_for(:country, :uniqueness)) }
    it { is_expected.not_to include(a_validator_for(:city, :uniqueness)) }
  end

  context 'with an integer column' do
    context 'with a nullable column' do
      let(:opts) { { only_integer: true, allow_nil: true } }
      it { is_expected.to include(a_validator_for(:age, :numericality, opts)) }
    end

    context 'with a non-nullable column' do
      let(:opts) { { only_integer: true, allow_nil: true } }
      it 'allows a nil value in the numericality validator' do
        expect(subject)
          .to include(a_validator_for(:socialness, :numericality, opts))
      end
    end

    context 'when used as enum' do
      it { is_expected.not_to include(a_validator_for(:sex, :numericality)) }
    end
  end

  context 'with a numeric column' do
    let(:opts) { { only_integer: false, allow_nil: true } }
    it { is_expected.to include(a_validator_for(:gpa, :numericality, opts)) }
  end

  context 'with a limited length string' do
    it { is_expected.to include(a_validator_for(:name, :length, maximum: 100)) }
  end

  context 'when passing a block' do
    let(:klass) do
      opts = disable_opts

      Class.new(ActiveRecord::Base) do
        self.table_name = 'resources'

        belongs_to :organisation

        valhammer do
          disable opts
        end
      end
    end

    subject { klass.validators }

    context 'disabling an attribute' do
      let(:disable_opts) { :name }

      it 'excludes all validators for the field' do
        [:presence, :length, :uniqueness].each do |v|
          expect(subject).not_to include(a_validator_for(:name, v))
        end
      end
    end

    context 'disabling a presence validator' do
      let(:disable_opts) { { name: :presence } }

      it 'excludes the disabled validator' do
        expect(subject).not_to include(a_validator_for(:name, :presence))
      end

      it 'includes other validators of the same type' do
        expect(subject).to include(a_validator_for(:mail, :presence))
      end

      it 'includes other validators for the same field' do
        expect(subject)
          .to include(a_validator_for(:name, :length, maximum: 100))
      end
    end

    context 'disabling a presence validator for an association' do
      let(:disable_opts) { { organisation: :presence } }

      it 'excludes the disabled validator' do
        expect(subject)
          .not_to include(a_validator_for(:organisation, :presence))
      end
    end

    context 'disabling an inclusion validator' do
      let(:disable_opts) { { injected: :inclusion } }

      it 'excludes the disabled validator' do
        expect(subject).not_to include(a_validator_for(:injected, :inclusion))
      end
    end

    context 'disabling a uniqueness validator' do
      let(:disable_opts) { { identifier: :uniqueness } }

      it 'excludes the disabled validator' do
        expect(subject)
          .not_to include(a_validator_for(:identifier, :uniqueness))
      end

      it 'includes other validators of the same type' do
        expect(subject).to include(a_validator_for(:name, :uniqueness))
      end

      it 'includes other validators for the same field' do
        expect(subject).to include(a_validator_for(:identifier, :presence))
      end
    end

    context 'disabling a numericality validator' do
      let(:disable_opts) { { gpa: :numericality } }

      it 'excludes the disabled validator' do
        expect(subject).not_to include(a_validator_for(:gpa, :numericality))
      end

      it 'includes other validators of the same type' do
        expect(subject).to include(a_validator_for(:age, :numericality))
      end

      it 'includes other validators for the same field' do
        expect(subject).to include(a_validator_for(:gpa, :presence))
      end
    end

    context 'disabling a length validator' do
      let(:disable_opts) { { name: :length } }

      it 'excludes the disabled validator' do
        expect(subject).not_to include(a_validator_for(:name, :length))
      end

      it 'includes other validators of the same type' do
        expect(subject).to include(a_validator_for(:identifier, :length))
      end

      it 'includes other validators for the same field' do
        expect(subject).to include(a_validator_for(:name, :presence))
      end
    end
  end

  context 'sanity check' do
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
                           name: 'Project Management', identifier: 'pm')
      end

      it { is_expected.to be_valid }
    end
  end
end
