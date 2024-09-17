import Config

config :phoenix_live_reload,
  dirs: [
    "priv/static",
    "lib/playground"
  ],
  backend: :fs_poll,
  backend_opts: [
    interval: 500
  ]
