defmodule Beamclaw2Web.FallbackController do
  use Beamclaw2Web, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: %{message: "Not found"}})
  end

  def call(conn, {:error, :invalid_transition}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{message: "Invalid status transition"}})
  end

  def call(conn, {:error, :invalid_params, message}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{message: message}})
  end
end
