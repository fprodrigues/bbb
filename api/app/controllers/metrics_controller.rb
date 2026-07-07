class MetricsController < ApplicationController
   skip_before_action :track_request_metrics, raise: false
  def index
    render plain: Prometheus::Client::Formats::Text.marshal(PROMETHEUS),
           content_type: "text/plain"
  end
end