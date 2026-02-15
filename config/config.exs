# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :beamclaw2,
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :beamclaw2, Beamclaw2Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: Beamclaw2Web.ErrorJSON],
    layout: false
  ],
  pubsub_server: Beamclaw2.PubSub,
  live_view: [signing_salt: "AuwMy1Ly"]

# Configure Elixir's Logger — JSON structured logging in prod, readable in dev/test
config :logger, :default_formatter,
  format: {Beamclaw2.Logger.JSONFormatter, :format},
  metadata: [:request_id, :module, :function, :line, :pid]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
