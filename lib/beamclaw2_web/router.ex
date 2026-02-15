defmodule Beamclaw2Web.Router do
  use Beamclaw2Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Beamclaw2Web do
    pipe_through :api

    resources "/agents", AgentController, except: [:new, :edit]
  end

  get "/health", Beamclaw2Web.HealthController, :index
end
