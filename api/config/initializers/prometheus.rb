require "prometheus/client"
require "prometheus/client/formats/text"

PROMETHEUS = Prometheus::Client.registry

def fetch_or_register_metric(registry, name, type, **options)
  metric = registry.get(name)
  return metric if metric

  registry.public_send(type, name, **options)
rescue Prometheus::Client::Registry::AlreadyRegisteredError
  registry.get(name)
end

HTTP_REQUESTS_TOTAL = fetch_or_register_metric(
  PROMETHEUS,
  :http_requests_total,
  :counter,
  docstring: "Total HTTP requests",
  labels: [:method, :path, :status]
)

HTTP_REQUEST_DURATION = fetch_or_register_metric(
  PROMETHEUS,
  :http_request_duration_seconds,
  :histogram,
  docstring: "HTTP request duration",
  labels: [:method, :path]
)

VOTES_TOTAL = fetch_or_register_metric(
  PROMETHEUS,
  :votes_total,
  :counter,
  docstring: "Total votes received",
  labels: [:participant_id]
)

VOTES_REJECTED_TOTAL = fetch_or_register_metric(
  PROMETHEUS,
  :votes_rejected_total,
  :counter,
  docstring: "Total votes rejected",
  labels: [:reason]
)