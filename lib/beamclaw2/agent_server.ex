defmodule Beamclaw2.AgentServer do
  @moduledoc """
  GenServer process representing a single agent.
  Registered via `Beamclaw2.AgentRegistry` for lookup by agent ID.
  """

  use GenServer

  require Logger

  alias Beamclaw2.Agent

  # --- Client API ---

  def start_link(attrs) do
    agent = Agent.new(attrs)
    GenServer.start_link(__MODULE__, agent, name: via(agent.id))
  end

  def get_state(agent_id) do
    case Registry.lookup(Beamclaw2.AgentRegistry, agent_id) do
      [{pid, _}] ->
        try do
          GenServer.call(pid, :get_state)
        catch
          :exit, _ -> {:error, :not_found}
        end

      [] ->
        {:error, :not_found}
    end
  end

  def update_status(agent_id, new_status) do
    case Registry.lookup(Beamclaw2.AgentRegistry, agent_id) do
      [{pid, _}] ->
        try do
          GenServer.call(pid, {:update_status, new_status})
        catch
          :exit, _ -> {:error, :not_found}
        end

      [] ->
        {:error, :not_found}
    end
  end

  # --- Server Callbacks ---

  @impl true
  def init(%Agent{} = agent) do
    Logger.info("Agent started: #{agent.id} (#{agent.name})")
    {:ok, agent}
  end

  @impl true
  def handle_call(:get_state, _from, agent) do
    {:reply, {:ok, agent}, agent}
  end

  @impl true
  def handle_call({:update_status, new_status}, _from, agent) do
    case Agent.transition(agent, new_status) do
      {:ok, updated} ->
        Logger.info("Agent #{agent.id} status: #{agent.status} → #{new_status}")
        {:reply, {:ok, updated}, updated}

      {:error, _} = error ->
        {:reply, error, agent}
    end
  end

  @impl true
  def terminate(reason, agent) do
    Logger.info("Agent terminated: #{agent.id} (reason: #{inspect(reason)})")
    :ok
  end

  defp via(agent_id) do
    {:via, Registry, {Beamclaw2.AgentRegistry, agent_id}}
  end
end
