# frozen_string_literal: true

# Puma configuration file

# Port
port ENV.fetch('PORT', 3001)

# Environment
environment ENV.fetch('RACK_ENV', 'development')

# Workers (for production)
workers ENV.fetch('WEB_CONCURRENCY', 2).to_i

# Threads
threads_count = ENV.fetch('MAX_THREADS', 5).to_i
threads threads_count, threads_count

# Preload app for better performance in production
preload_app!

# Daemonize in production
# daemonize false

# Logging
if ENV['RACK_ENV'] == 'production'
  stdout_redirect 'log/puma_access.log', 'log/puma_error.log', true
end

# Restart when USR1 signal is received
on_restart do
  puts 'Puma restarting...'
end
