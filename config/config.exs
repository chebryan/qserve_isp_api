# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :qserve_isp_api,
  ecto_repos: [QserveIspApi.Repo],
  generators: [timestamp_type: :utc_datetime]

# config :qserve_isp_api
config :qserve_isp_api, QserveIspApi.Auth.JWT,
  secret_key: "rtf5Vt+CdYqHqRf00z85TQfpcym/htqwQOuqBXdtS/0="


# Configures the endpoint
config :qserve_isp_api, QserveIspApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: QserveIspApiWeb.ErrorHTML, json: QserveIspApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: QserveIspApi.PubSub,
  live_view: [signing_salt: "/8/rmF6y"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :qserve_isp_api, QserveIspApi.Mailer, adapter: Swoosh.Adapters.Local

config :qserve_isp_api, QserveIspApi.PubSub,
  adapter: Phoenix.PubSub.PG2

config :qserve_isp_api, :mpesa,
  stk_push_url: "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
  token_url: "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
  callback_url: "https://api.qserve-isp.net/api/pay/callback"

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  qserve_isp_api: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]




# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  qserve_isp_api: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
