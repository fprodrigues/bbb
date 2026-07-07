class ApplicationController < ActionController::API
  around_action :track_request_metrics

  private

  def track_request_metrics
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    yield
  ensure
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

    path = request.path
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
end