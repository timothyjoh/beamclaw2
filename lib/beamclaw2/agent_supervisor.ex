defmodule Beamclaw2.AgentSupervisor do
  @moduledoc """
  DynamicSupervisor for agent processes.
  Agents are started as :temporary — they are not restarted on crash.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_agent(attrs) do
    spec = {Beamclaw2.AgentServer, attrs}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_agent(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
