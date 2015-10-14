require 'spec_helper'

describe Bosh::Director::DeploymentPlan::InstanceRepository do
  let(:plan) do
    network = BD::DeploymentPlan::DynamicNetwork.new('name-7', [], logger)
    ip_repo = BD::DeploymentPlan::InMemoryIpRepo.new(logger)
    vip_repo = BD::DeploymentPlan::VipRepo.new(logger)
    ip_provider = BD::DeploymentPlan::IpProviderV2.new(ip_repo, vip_repo, true, logger)
    model = BD::Models::Deployment.make
    instance_double('Bosh::Director::DeploymentPlan::Planner',
      network: network,
      ip_provider: ip_provider,
      model: model
    )
  end

  let(:job) do
    job = BD::DeploymentPlan::Job.new(logger)
    job.name = 'job-name'
    job
  end

  before do
    allow(SecureRandom).to receive(:uuid).and_return('uuid-1')
  end

  describe '#fetch_existing' do
    let(:existing_instance) do
      existing_instance = Bosh::Director::Models::Instance.make(
        deployment_id: 'deployment-id',
        job: 'job-name',
        index: 1,
        state: 'started',
        compilation: false,
        uuid: 'uuid-2',
        availability_zone: 'az-name',
        bootstrap: false,
      )
      existing_instance.add_ip_address(BD::Models::IpAddress.make)
      existing_instance
    end

    it 'returns an DeploymentPlan::Instance with a bound Models::Instance and bound network reservations' do
      desired_instance = BD::DeploymentPlan::DesiredInstance.new(job, nil, plan)
      instance = BD::DeploymentPlan::InstanceRepository.new(logger).fetch_existing(desired_instance, existing_instance, {})

      expect(instance.model).to eq(existing_instance)
      expect(instance.uuid).to eq(existing_instance.uuid)
      expect(instance.existing_network_reservations.count).to eq(1)
      expect(instance.state).to eq(existing_instance.state)
    end

    context 'when DesiredInstance has a state set on it' do
      it 'returns a DeploymentPlan::Instance with the state of the DesiredInstance' do
        desired_instance = BD::DeploymentPlan::DesiredInstance.new(job, 'stopped', plan)
        instance = BD::DeploymentPlan::InstanceRepository.new(logger).fetch_existing(desired_instance, existing_instance, {})

        expect(instance.state).to eq(desired_instance.state)
        expect(instance.uuid).to eq(existing_instance.uuid)
      end
    end
  end

  describe '#create' do
    it 'should persist an instance with attributes from the desired_instance' do
      az = BD::DeploymentPlan::AvailabilityZone.new('az-name', {})
      desired_instance = BD::DeploymentPlan::DesiredInstance.new(job, nil, plan, az)

      BD::DeploymentPlan::InstanceRepository.new(logger).create(desired_instance, 1)

      persisted_instance = BD::Models::Instance.find(uuid: 'uuid-1')
      expect(persisted_instance.deployment_id).to eq(plan.model.id)
      expect(persisted_instance.job).to eq(job.name)
      expect(persisted_instance.index).to eq(1)
      expect(persisted_instance.state).to eq('started')
      expect(persisted_instance.compilation).to eq(job.compilation?)
      expect(persisted_instance.uuid).to eq('uuid-1')
      expect(persisted_instance.availability_zone).to eq('az-name')
    end

    context 'when DesiredInstance has a state set on it' do
      it 'uses the state from the DesiredInstance' do
        desired_instance = BD::DeploymentPlan::DesiredInstance.new(job, 'stopped', plan)

        BD::DeploymentPlan::InstanceRepository.new(logger).create(desired_instance, 1)

        persisted_instance = BD::Models::Instance.find(uuid: 'uuid-1')
        expect(persisted_instance.state).to eq(desired_instance.state)
      end
    end
  end
end
