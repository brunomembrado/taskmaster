import Config

# Note: TLS termination should be handled by the reverse proxy (e.g. Fly.io, Nginx).
# Uncomment force_ssl when deploying behind a proxy that sets X-Forwarded-Proto.
# config :taskmaster, TaskmasterWeb.Endpoint,
#   force_ssl: [rewrite_on: [:x_forwarded_proto]]

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
