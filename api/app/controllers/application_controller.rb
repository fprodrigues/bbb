class ApplicationController < ActionController::API
  around_action :track_request_metrics

  private

  def track_request_metrics
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    yield
  ensure
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

    path = normalized_path
    method = request.method
    status = response.status.to_s

    HTTP_REQUESTS_TOTAL.increment(
      labels: {
        method: method,
        path: path,
        status: status
      }
    )

    HTTP_REQUEST_DURATION.observe(
      duration,
      labels: {
        method: method,
        path: path
      }
    )
  end

  def normalized_path
    request.path.gsub(%r{/\d+}, "/:id")
  rescue StandardError
    request.path
  end
end