defmodule Beamclaw2.AgentManager do
  @moduledoc """
  Public API for agent lifecycle management.
  Orchestrates AgentSupervisor, AgentServer, and AgentRegistry.
  """

  alias Beamclaw2.{AgentServer, AgentSupervisor}

  @doc "Create and start a new agent process."
  @spec create_agent(map()) :: {:ok, Beamclaw2.Agent.t()} | {:error, term()}
  def create_agent(attrs \\ %{}) do
    case AgentSupervisor.start_agent(attrs) do
      {:ok, pid} ->
        GenServer.call(pid, :get_state)

      {:error, _} = error ->
        error
    end
  end

  @doc "Get agent state by ID."
  @spec get_agent(String.t()) :: {:ok, Beamclaw2.Agent.t()} | {:error, :not_found}
  def get_agent(agent_id) do
    AgentServer.get_state(agent_id)
  end

  @doc "List all running agents."
  @spec list_agents() :: [Beamclaw2.Agent.t()]
  def list_agents do
    Registry.select(Beamclaw2.AgentRegistry, [{{:_, :"$1", :_}, [], [:"$1"]}])
    |> Enum.flat_map(fn pid ->
      try do
        case GenServer.call(pid, :get_state) do
          {:ok, agent} -> [agent]
          _ -> []
        end
      catch
        :exit, _ -> []
      end
    end)
  end

  @doc "Update agent status."
  @spec update_status(String.t(), Beamclaw2.Agent.status()) ::
          {:ok, Beamclaw2.Agent.t()} | {:error, term()}
  def update_status(agent_id, new_status) do
    AgentServer.update_status(agent_id, new_status)
  end

  @doc "Stop an agent gracefully. Transitions to :stopped before termination."
  @spec stop_agent(String.t()) :: :ok | {:error, :not_found}
  def stop_agent(agent_id) do
    case Registry.lookup(Beamclaw2.AgentRegistry, agent_id) do
      [{pid, _}] ->
        try do
          GenServer.call(pid, {:update_status, :stopped})
        catch
          :exit, _ -> :ok
        end

        AgentSupervisor.stop_agent(pid)

      [] ->
        {:error, :not_found}
    end
  end
end
