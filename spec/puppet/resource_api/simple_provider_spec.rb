# frozen_string_literal: true

require 'spec_helper'
require 'puppet/resource_api/simple_provider'

RSpec.describe Puppet::ResourceApi::SimpleProvider do
  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:type_def) { instance_double('Puppet::ResourceApi::TypeDefinition', 'type_def') }
  let(:provider_class) do
    Class.new(described_class) do
      def get(context, _names = nil); end

      def create(context, _name, _should); end

      def update(context, _name, _should); end

      def delete(context, _name); end
    end
  end

  let(:provider) { provider_class.new }

  before(:each) do
    allow(context).to receive(:type).and_return(type_def)
    allow(type_def).to receive(:ensurable?).and_return(true)
  end

  context 'without overriding the crud methods' do
    it 'create fails' do
      expect { described_class.new.create(context, nil, nil) }.to raise_error StandardError, %r{has not implemented.*create}
    end
    it 'update fails' do
      expect { described_class.new.update(context, nil, nil) }.to raise_error StandardError, %r{has not implemented.*update}
    end
    it 'delete fails' do
      expect { described_class.new.delete(context, nil) }.to raise_error StandardError, %r{has not implemented.*delete}
    end
  end

  context 'with no changes' do
    let(:changes) { {} }

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'does not call update' do
      expect(provider).to receive(:update).never
      provider.set(context, changes)
    end
    it 'does not call delete' do
      expect(provider).to receive(:delete).never
      provider.set(context, changes)
    end
  end

  context 'with a single change to create a resource' do
    let(:should_values) { { name: 'title', ensure: 'present' } }
    let(:changes) do
      { 'title' =>
        {
          should: should_values,
        } }
    end

    before(:each) do
      allow(context).to receive(:creating).with('title').and_yield
      allow(context).to receive(:type).and_return(type_def)
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:check_schema)
      allow(type_def).to receive(:namevars).and_return([:name])
    end

    it 'calls create once' do
      expect(provider).to receive(:create).with(context, 'title', should_values).once
      provider.set(context, changes)
    end
    it 'does not call update' do
      expect(provider).to receive(:update).never
      provider.set(context, changes)
    end
    it 'does not call delete' do
      expect(provider).to receive(:delete).never
      provider.set(context, changes)
    end
    it 'calls get once' do
      expect(provider).to receive(:get).once
      provider.set(context, changes)
    end

    context 'with a type that supports `simple_get_filter`' do
      before(:each) do
        allow(context).to receive(:type).and_return(type_def)
        allow(type_def).to receive(:feature?).with('simple_get_filter').and_return(true)
      end

      it 'calls `get` with name' do
        expect(provider).to receive(:get).with(context, ['title'])
        provider.set(context, changes)
      end
    end
  end

  context 'with a single change to update a resource with :is supplied' do
    let(:is_values) { { name: 'title', ensure: 'present' } }
    let(:should_values) { { name: 'title', ensure: 'present' } }
    let(:changes) do
      { 'title' =>
        {
          is: is_values,
          should: should_values,
        } }
    end

    before(:each) do
      allow(context).to receive(:updating).with('title').and_yield
      allow(context).to receive(:type).and_return(type_def)
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:namevars).and_return([:name])
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'calls update once' do
      expect(provider).to receive(:update).with(context, 'title', should_values).once
      provider.set(context, changes)
    end
    it 'does not call delete' do
      expect(provider).to receive(:delete).never
      provider.set(context, changes)
    end
    it 'does not call get' do
      expect(provider).to receive(:get).never
      provider.set(context, changes)
    end
    it 'does not check the schema' do
      expect(type_def).to receive(:check_schema).never
      provider.set(context, changes)
    end
  end

  context 'with a single change to update a resource without :is supplied' do
    let(:is_values) { [{ name: 'title', ensure: 'present' }] }
    let(:should_values) { { name: 'title', ensure: 'present' } }
    let(:changes) do
      { 'title' =>
        {
          should: should_values,
        } }
    end

    before(:each) do
      allow(context).to receive(:updating).with('title').and_yield
      allow(context).to receive(:type).and_return(type_def)
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:check_schema)
      allow(type_def).to receive(:namevars).and_return([:name])
      allow(provider).to receive(:get).with(context).and_return(is_values)
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'calls update once' do
      expect(provider).to receive(:update).with(context, 'title', should_values).once
      provider.set(context, changes)
    end
    it 'calls get once' do
      expect(provider).to receive(:get).with(context).once
      provider.set(context, changes)
    end
    it 'does not check the schema' do
      expect(type_def).to receive(:check_schema).with(is_values.first)
      provider.set(context, changes)
    end
    it 'does not call delete' do
      expect(provider).to receive(:delete).never
      provider.set(context, changes)
    end

    context 'with a type that supports `simple_get_filter`' do
      before(:each) do
        allow(type_def).to receive(:feature?).with('simple_get_filter').and_return(true)
        allow(provider).to receive(:get).with(context, ['title']).and_return(is_values)
      end

      it 'calls `get` with name' do
        expect(provider).to receive(:get).with(context, ['title'])
        provider.set(context, changes)
      end
    end
  end

  context 'with a single change to update a resource with an optional ensure' do
    let(:is_values) { { name: 'title', ensure: 'present', prop: 'a' } }
    let(:should_values) { { name: 'title', prop: 'b' } }
    let(:changes) do
      { 'title' =>
        {
          is: is_values,
          should: should_values,
        } }
    end

    before(:each) do
      allow(context).to receive(:updating).with('title').and_yield
      allow(context).to receive(:type).and_return(type_def)
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:namevars).and_return([:name])
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'calls update once' do
      expect(provider).to receive(:update).with(context, 'title', should_values).once
      provider.set(context, changes)
    end
    it 'does not call delete' do
      expect(provider).to receive(:delete).never
      provider.set(context, changes)
    end
  end

  context 'with a single change to delete a resource with :is supplied' do
    let(:is_values) { { name: 'title', ensure: 'present' } }
    let(:should_values) { { name: 'title', ensure: 'absent' } }
    let(:changes) do
      { 'title' =>
        {
          is: is_values,
          should: should_values,
        } }
    end

    before(:each) do
      allow(context).to receive(:deleting).with('title').and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:namevars).and_return([:name])
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'does not call update' do
      expect(provider).to receive(:update).never
      provider.set(context, changes)
    end
    it 'calls delete once' do
      expect(provider).to receive(:delete).with(context, 'title').once
      provider.set(context, changes)
    end
    it 'does not call get' do
      expect(provider).to receive(:get).never
      provider.set(context, changes)
    end
  end

  context 'with a single change to delete a resource without :is supplied' do
    let(:is_values) { [{ name: 'title', ensure: 'present' }] }
    let(:should_values) { { name: 'title', ensure: 'absent' } }
    let(:changes) do
      { 'title' =>
        {
          should: should_values,
        } }
    end

    before(:each) do
      allow(context).to receive(:deleting).with('title').and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:check_schema)
      allow(type_def).to receive(:namevars).and_return([:name])
      allow(provider).to receive(:get).with(context).and_return(is_values)
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'does not call update' do
      expect(provider).to receive(:update).never
      provider.set(context, changes)
    end
    it 'calls delete once' do
      expect(provider).to receive(:delete).with(context, 'title').once
      provider.set(context, changes)
    end
    it 'calls check_schema' do
      expect(type_def).to receive(:check_schema).once
      provider.set(context, changes)
    end
    it 'calls get once to retrieve "is"' do
      expect(provider).to receive(:get).with(context).once
      provider.set(context, changes)
    end

    context 'with a type that supports `simple_get_filter`' do
      before(:each) do
        allow(type_def).to receive(:feature?).with('simple_get_filter').and_return(true)
      end

      it 'calls `get` with name' do
        expect(provider).to receive(:get).with(context, ['title'])
        provider.set(context, changes)
      end
    end
  end

  context 'with multiple changes' do
    let(:changes) do
      { 'to create' =>
        {
          should: { name: 'to create', ensure: 'present' },
        },
        'to update' =>
        {
          is: { name: 'to update', ensure: 'present' },
          should: { name: 'to update', ensure: 'present' },
        },
        'to delete' =>
        {
          is: { name: 'to create', ensure: 'present' },
          should: { name: 'to create', ensure: 'absent' },
        } }
    end

    before(:each) do
      allow(context).to receive(:creating).with('to create').and_yield
      allow(context).to receive(:updating).with('to update').and_yield
      allow(context).to receive(:deleting).with('to delete').and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter').exactly(3).times
      allow(type_def).to receive(:namevars).and_return([:name])
    end

    it 'calls the crud methods' do
      expect(provider).to receive(:create).with(context, 'to create', hash_including(name: 'to create'))
      expect(provider).to receive(:update).with(context, 'to update', hash_including(name: 'to update'))
      expect(provider).to receive(:delete).with(context, 'to delete')
      expect(type_def).to receive(:check_schema)
      provider.set(context, changes)
    end
  end

  context 'with a type that does not implement ensurable' do
    let(:is_values) { { name: 'title', content: 'foo' } }
    let(:should_values) { { name: 'title', content: 'bar' } }
    let(:changes) do
      { 'title' =>
            {
              is: is_values,
              should: should_values,
            } }
    end

    before(:each) do
      allow(context).to receive(:updating).with('title').and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:ensurable?).and_return(false)
    end

    it { expect { provider.set(context, changes) }.to raise_error %r{SimpleProvider cannot be used with a Type that is not ensurable} }
  end

  context 'with a single change to create a composite namevar resource' do
    let(:should_values) { { name1: 'title1', name2: 'title2', ensure: 'present' } }
    let(:changes) do
      {
        { name1: 'title1', name2: 'title2' } =>
          {
            should: should_values,
          },
      }
    end

    before(:each) do
      allow(context).to receive(:creating).with({ name1: 'title1', name2: 'title2' }).and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter').and_return(true)
      allow(type_def).to receive(:namevars).and_return([:name1, :name2])
      allow(type_def).to receive(:check_schema)
    end

    it 'calls create once' do
      expect(provider).to receive(:create).with(context, { name1: 'title1', name2: 'title2' }, should_values).once
      provider.set(context, changes)
    end
    it 'does not call update' do
      expect(provider).to receive(:update).never
      provider.set(context, changes)
    end
    it 'does not call delete' do
      expect(provider).to receive(:delete).never
      provider.set(context, changes)
    end

    context 'with a type that supports `simple_get_filter`' do
      before(:each) do
        allow(type_def).to receive(:feature?).with('simple_get_filter').and_return(true)
      end

      it 'calls `get` with name' do
        expect(provider).to receive(:get).with(context, [{ name1: 'title1', name2: 'title2' }])
        provider.set(context, changes)
      end
    end
  end

  context 'with a single change to update a composite namevar resource with :is supplied' do
    let(:is_values) { { name1: 'title1', name2: 'title2', ensure: 'present' } }
    let(:should_values) { { name1: 'title1', name2: 'title2', ensure: 'present' } }
    let(:changes) do
      {
        { name1: 'title1', name2: 'title2' } =>
          {
            is: is_values,
            should: should_values,
          },
      }
    end

    before(:each) do
      allow(context).to receive(:updating).with({ name1: 'title1', name2: 'title2' }).and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:check_schema)
      allow(type_def).to receive(:namevars).and_return([:name1, :name2])
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'calls update once' do
      expect(provider).to receive(:update).with(context, { name1: 'title1', name2: 'title2' }, should_values).once
      provider.set(context, changes)
    end
    it 'does not call delete' do
      expect(provider).to receive(:delete).never
      provider.set(context, changes)
    end
    it 'does not call get' do
      expect(provider).to receive(:get).never
      provider.set(context, changes)
    end
  end

  context 'with a single change to update a composite namevar resource without :is supplied' do
    let(:is_values) { [{ name1: 'title1', name2: 'title2', ensure: 'present' }] }
    let(:should_values) { { name1: 'title1', name2: 'title2', ensure: 'present' } }
    let(:changes) do
      {
        { name1: 'title1', name2: 'title2' } =>
          {
            should: should_values,
          },
      }
    end

    before(:each) do
      allow(context).to receive(:updating).with({ name1: 'title1', name2: 'title2' }).and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:check_schema)
      allow(type_def).to receive(:namevars).and_return([:name1, :name2])
      allow(provider).to receive(:get).with(context).and_return(is_values)
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'calls update once' do
      expect(provider).to receive(:update).with(context, { name1: 'title1', name2: 'title2' }, should_values).once
      provider.set(context, changes)
    end
    it 'does not call delete' do
      expect(provider).to receive(:delete).never
      provider.set(context, changes)
    end
    it 'calls get once' do
      expect(provider).to receive(:get).once
      provider.set(context, changes)
    end

    context 'with a type that supports `simple_get_filter`' do
      before(:each) do
        allow(type_def).to receive(:feature?).with('simple_get_filter').and_return(true)
        allow(provider).to receive(:get).with(context, [{ name1: 'title1', name2: 'title2' }]).and_return(is_values)
      end

      it 'calls `get` with name' do
        expect(provider).to receive(:get).with(context, [{ name1: 'title1', name2: 'title2' }]).once
        provider.set(context, changes)
      end
    end
  end

  context 'with a single change to delete a composite namevar resource with :is supplied' do
    let(:is_values) { { name1: 'title1', name2: 'title2', ensure: 'present' } }
    let(:should_values) { { name1: 'title1', name2: 'title2', ensure: 'absent' } }
    let(:changes) do
      {
        { name1: 'title1', name2: 'title2' } =>
          {
            is: is_values,
            should: should_values,
          },
      }
    end

    before(:each) do
      allow(context).to receive(:deleting).with({ name1: 'title1', name2: 'title2' }).and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:namevars).and_return([:name1, :name2])
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'does not call update' do
      expect(provider).to receive(:update).never
      provider.set(context, changes)
    end
    it 'calls delete once' do
      expect(provider).to receive(:delete).with(context, { name1: 'title1', name2: 'title2' }).once
      provider.set(context, changes)
    end
    it 'does not call get' do
      expect(provider).to receive(:get).never
      provider.set(context, changes)
    end
  end

  context 'with a single change to delete a composite namevar resource without :is supplied' do
    let(:is_values) { [{ name1: 'title1', name2: 'title2', ensure: 'present' }] }
    let(:should_values) { { name1: 'title1', name2: 'title2', ensure: 'absent' } }
    let(:changes) do
      {
        { name1: 'title1', name2: 'title2' } =>
          {
            should: should_values,
          },
      }
    end

    before(:each) do
      allow(context).to receive(:deleting).with({ name1: 'title1', name2: 'title2' }).and_yield
      allow(type_def).to receive(:feature?).with('simple_get_filter')
      allow(type_def).to receive(:check_schema)
      allow(type_def).to receive(:namevars).and_return([:name1, :name2])
      allow(provider).to receive(:get).with(context).and_return(is_values)
    end

    it 'does not call create' do
      expect(provider).to receive(:create).never
      provider.set(context, changes)
    end
    it 'does not call update' do
      expect(provider).to receive(:update).never
      provider.set(context, changes)
    end
    it 'calls delete once' do
      expect(provider).to receive(:delete).with(context, { name1: 'title1', name2: 'title2' }).once
      provider.set(context, changes)
    end
    it 'calls get once' do
      expect(provider).to receive(:get).once
      provider.set(context, changes)
    end

    context 'with a type that supports `simple_get_filter`' do
      before(:each) do
        allow(type_def).to receive(:feature?).with('simple_get_filter').and_return(true)
      end

      it 'calls `get` with name' do
        expect(provider).to receive(:get).with(context, [{ name1: 'title1', name2: 'title2' }])
        provider.set(context, changes)
      end
    end
  end
end
