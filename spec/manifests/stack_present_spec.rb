# frozen_string_literal: true

require 'spec_helper'

# present declarations ride the stack to the delivery boundary as pure data;
# each verb assembles its own scenario's pipeline there. Undeclared stacks
# assemble the identity, so their payloads stay byte-identical — pinned by
# the kubectl_ops boundary specs, which run without declarations.
RSpec.describe 'stack present declarations' do
  let(:ops) { Matsuri::Tasks::KubectlOps }

  def run_double(task_class)
    instance_double(task_class, run!: true)
  end

  describe 'declaration' do
    it 'appends members per scenario, in declaration order' do
      stack = Matsuri.define(:stack, 'present-order') do
        present :on_apply,  'team-label'
        present :on_apply,  :second
        present :on_create, 'team-label'
      end

      expect(stack.presents[:on_apply]).to eq ['team-label', :second]
      expect(stack.presents[:on_create]).to eq ['team-label']
    end

    it 'stays local to the declaring stack' do
      declared = Matsuri.define(:stack, 'present-local') do
        present :on_apply, 'team-label'
      end

      expect(declared.presents[:on_apply]).to eq ['team-label']
      expect(Matsuri::Stack.presents).to be_nil
      expect(Matsuri::Registry.stack('app').presents).to be_nil
    end
  end

  describe 'delivery' do
    it 'assembles :on_apply through converge' do
      stack = Matsuri.define(:stack, 'present-apply') do
        needs :deployment, 'app-web'
        present :on_apply, 'team-label'
      end

      expect(ops::Apply).to receive(:new) do |args|
        expect(args[:input]).to match(/team: platform/)
        run_double(ops::Apply)
      end
      stack.new.converge!
    end

    it 'keeps scenarios separate: :on_create members never ride apply' do
      stack = Matsuri.define(:stack, 'present-separate') do
        needs :deployment, 'app-web'
        present :on_create, 'team-label'
      end

      expect(ops::Apply).to receive(:new) do |args|
        expect(args[:input]).not_to match(/team: platform/)
        run_double(ops::Apply)
      end
      stack.new.converge!
    end

    it 'assembles :on_create on the create leg of recreate-policy members' do
      stack = Matsuri.define(:stack, 'present-create') do
        needs :config_map, 'app-settings'
        present :on_create, 'team-label'
      end

      allow(ops::Get).to receive(:new).and_return(instance_double(ops::Get, exists?: false))
      expect(ops::Create).to receive(:new) do |args|
        expect(args[:input]).to match(/team: platform/)
        run_double(ops::Create)
      end
      stack.new.converge!
    end

    it 'applies a match combinator selectively across members' do
      stack = Matsuri.define(:stack, 'present-matched') do
        needs :deployment, 'app-web'
        needs :service,    'app-web'
        present :on_apply, match_deployments('team-label')
      end

      inputs = {}
      allow(ops::Apply).to receive(:new) do |args|
        inputs[args[:description]] = args[:input]
        run_double(ops::Apply)
      end
      stack.new.converge!

      expect(inputs.fetch('deployment/app-web')).to match(/team: platform/)
      expect(inputs.fetch('service/app-web')).not_to match(/team: platform/)
    end

    it 'closes a declaration-time value into a leaf member' do
      pin = Matsuri::Transform::Callable.new(label: 'pin-replicas') do |m|
        m.set([:spec, :replicas], 7)
      end
      stack = Matsuri.define(:stack, 'present-leaf') do
        needs :deployment, 'app-web'
      end
      stack.present :on_apply, pin

      expect(ops::Apply).to receive(:new) do |args|
        expect(args[:input]).to match(/replicas: 7/)
        run_double(ops::Apply)
      end
      stack.new.converge!
    end

    it 'diff previews the presented payload' do
      stack = Matsuri.define(:stack, 'present-diff') do
        needs :deployment, 'app-web'
        present :on_apply, 'team-label'
      end

      expect(ops::Diff).to receive(:new) do |args|
        expect(args[:input]).to match(/team: platform/)
        run_double(ops::Diff)
      end
      stack.new.diff!
    end
  end
end
