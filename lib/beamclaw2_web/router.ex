defmodule Beamclaw2Web.Router do
  use Beamclaw2Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Beamclaw2Web do
    pipe_through :api

    resources "/agents", AgentController, except: [:new, :edit]

    post "/chat/completions", ChatController, :create
    post "/chat/completions/stream", ChatController, :stream
  end

  get "/health", Beamclaw2Web.HealthController, :index
end
