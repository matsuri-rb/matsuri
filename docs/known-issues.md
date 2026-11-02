# Known Issues

## CronJob templates inherit Pod's restartPolicy default

Pod defaults `restart_policy` to `Always`, and nothing in the CronJob
chain overrides it. Kubernetes rejects `Always` in Job pod templates
(`OnFailure` or `Never` are the lawful values), so a cron job built
through the pod template emits a template the API server refuses unless
the pod definition declares its own policy:

```ruby
Matsuri.define :pod, 'report' do
  let(:restart_policy) { 'OnFailure' }
end
```

The fixture pod `report` models this. Whether CronJob should own a
Job-lawful default for its template, rather than inheriting Pod's, is an
open design question — deferred.
