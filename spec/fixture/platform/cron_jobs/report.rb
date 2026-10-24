Matsuri.define :cron_job, 'report' do
  let(:schedule) { '0 4 * * *' }
  let(:pod_name) { 'report' }
end
