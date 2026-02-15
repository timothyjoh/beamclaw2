defmodule Beamclaw2Web.AgentJSON do
  @moduledoc """
  JSON rendering for Agent resources.
  """

  alias Beamclaw2.Agent

  def index(%{agents: agents}) do
    %{data: Enum.map(agents, &agent_to_map/1)}
  end

  def show(%{agent: agent}) do
    %{data: agent_to_map(agent)}
  end

  defp agent_to_map(%Agent{} = agent) do
    %{
      id: agent.id,
      name: agent.name,
      status: Atom.to_string(agent.status),
      metadata: agent.metadata,
      created_at: DateTime.to_iso8601(agent.created_at),
      updated_at: DateTime.to_iso8601(agent.updated_at)
    }
  end
end
