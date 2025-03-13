# Releases

## v0.12.1

### Introduce `Metrics::Config` to Expose `prepare` Hook

The `metrics` gem uses aspect-oriented programming to wrap existing methods to emit metrics. However, while there are some reasonable defaults for emitting metrics, it can be useful to customize the behavior and level of detail. To that end, the `metrics` gem now optionally loads a `config/metrics.rb` which includes a `prepare` hook that can be used to load additional providers.

``` ruby
# config/metrics.rb

def prepare
	require 'metrics/provider/async'
	require 'metrics/provider/async/http'
end
```

The `prepare` method is called immediately after the metrics backend is loaded. You can require any provider you want in this file, or even add your own custom providers.
