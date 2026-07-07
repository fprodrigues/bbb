class MetricsController < ApplicationController
  def index
    render plain: Prometheus::Client::Formats::Text.marshal(PROMETHEUS),
           content_type: "text/plain"
  end
end