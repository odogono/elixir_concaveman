import Config

if Mix.env() == :dev do
  config :phoenix_live_reload,
    dirs: [
      "priv/static",
      "lib/playground"
    ],
    backend: :fs_poll,
    backend_opts: [
      interval: 500
    ]
end
