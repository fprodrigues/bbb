require "prometheus/client"
require "prometheus/client/formats/text"

PROMETHEUS = Prometheus::Client.registry

module PrometheusMetrics
  module_function

  def counter(name, **options)
    PROMETHEUS.get(name) || PROMETHEUS.counter(name, **options)
  end

  def histogram(name, **options)
    PROMETHEUS.get(name) || PROMETHEUS.histogram(name, **options)
  end

  def gauge(name, **options)
    PROMETHEUS.get(name) || PROMETHEUS.gauge(name, **options)
  end
end

HTTP_REQUESTS_TOTAL = PrometheusMetrics.counter(
  :http_requests_total,
  docstring: "Total HTTP requests",
  labels: [:method, :path, :status]
)

HTTP_REQUEST_DURATION = PrometheusMetrics.histogram(
  :http_request_duration_seconds,
  docstring: "HTTP request duration",
  labels: [:method, :path]
)

VOTES_TOTAL = PrometheusMetrics.counter(
  :votes_total,
  docstring: "Total votes received",
  labels: [:participant_id]
)

VOTES_REJECTED_TOTAL = PrometheusMetrics.counter(
  :votes_rejected_total,
  docstring: "Total votes rejected",
  labels: [:reason]
)

CURRENT_ELECTION_TOTAL_VOTES = PrometheusMetrics.gauge(
  :current_election_total_votes,
  docstring: "Total votes in the current running election"
)

CURRENT_ELECTION_PARTICIPANT_VOTES = PrometheusMetrics.gauge(
  :current_election_participant_votes,
  docstring: "Votes per participant in the current running election",
  labels: [:participant_id, :participant_name]
)

CURRENT_ELECTION_PARTICIPANT_ACTIVE = PrometheusMetrics.gauge(
  :current_election_participant_active,
  docstring: "Whether a participant is active in the current running election",
  labels: [:participant_id, :participant_name]
)
