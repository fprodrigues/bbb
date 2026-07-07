max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 10)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)

threads min_threads_count, max_threads_count

port ENV.fetch("PORT", 3001)
environment ENV.fetch("RAILS_ENV", "development")

workers ENV.fetch("WEB_CONCURRENCY", 0).to_i

preload_app!

plugin :tmp_restart