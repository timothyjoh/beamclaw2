defmodule Beamclaw2Web.AgentController do
  use Beamclaw2Web, :controller

  alias Beamclaw2.AgentManager

  action_fallback Beamclaw2Web.FallbackController

  @valid_statuses ~w(initializing idle running completed failed stopped)

  def index(conn, _params) do
    agents = AgentManager.list_agents()
    render(conn, :index, agents: agents)
  end

  def create(conn, params) do
    attrs = %{
      name: Map.get(params, "name"),
      metadata: Map.get(params, "metadata", %{})
    }

    case attrs.name do
      nil ->
        {:error, :invalid_params, "name is required"}

      "" ->
        {:error, :invalid_params, "name is required"}

      _name ->
        with {:ok, agent} <- AgentManager.create_agent(attrs) do
          conn
          |> put_status(:created)
          |> render(:show, agent: agent)
        end
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, agent} <- AgentManager.get_agent(id) do
      render(conn, :show, agent: agent)
    end
  end

  def update(conn, %{"id" => id} = params) do
    status_string = Map.get(params, "status")

    cond do
      is_nil(status_string) ->
        {:error, :invalid_params, "status is required"}

      status_string not in @valid_statuses ->
        {:error, :invalid_params, "invalid status: #{status_string}"}

      true ->
        status = String.to_existing_atom(status_string)

        with {:ok, agent} <- AgentManager.update_status(id, status) do
          render(conn, :show, agent: agent)
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- AgentManager.stop_agent(id) do
      send_resp(conn, :no_content, "")
    end
  end
end
