defmodule Beamclaw2.Application do
  @moduledoc """
  OTP Application for BeamClaw2.

  Starts the supervision tree with telemetry, PubSub, and the web endpoint.
  Logs lifecycle events on start and stop.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Beamclaw2Web.Telemetry,
      {DNSCluster, query: Application.get_env(:beamclaw2, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Beamclaw2.PubSub},
      {Registry, keys: :unique, name: Beamclaw2.AgentRegistry},
      Beamclaw2.AgentSupervisor,
      Beamclaw2Web.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Beamclaw2.Supervisor]
    result = Supervisor.start_link(children, opts)

    case result do
      {:ok, _pid} ->
        require Logger
        Logger.info("BeamClaw2 started")

      _ ->
        :ok
    end

    result
  end

  @impl true
  def prep_stop(state) do
    require Logger
    Logger.info("BeamClaw2 stopping")
    state
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Beamclaw2Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
