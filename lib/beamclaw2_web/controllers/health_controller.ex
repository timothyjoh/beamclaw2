defmodule Beamclaw2Web.HealthController do
  @moduledoc """
  Health check endpoint for BeamClaw2.

  Returns application status and current timestamp.
  """

  use Beamclaw2Web, :controller

  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end
end
