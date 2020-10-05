# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :rps,
  ecto_repos: [RPS.Repo],
  round_timeout: 10_000

# Configures the endpoint
config :rps, RPSWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SzcG5/1PS2hYdXvo323LhM3DWlL5X8iKouX6TfRbQc1OMzbd/2P38MMRvezPf3oU",
  render_errors: [view: RPSWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: RPSWeb.PubSub,
  live_view: [signing_salt: "72U1u2O2"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
