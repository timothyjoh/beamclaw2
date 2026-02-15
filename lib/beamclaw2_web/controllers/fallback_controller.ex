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

  def call(conn, {:error, :invalid_messages}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: %{message: "Invalid messages: must be a non-empty array of {role, content} objects"}
    })
  end

  def call(conn, {:error, :missing_api_key}) do
    conn
    |> put_status(:service_unavailable)
    |> json(%{error: %{message: "LLM provider not configured"}})
  end

  def call(conn, {:error, :api_error, details}) do
    conn
    |> put_status(:bad_gateway)
    |> json(%{error: %{message: "LLM provider error", details: details}})
  end

  def call(conn, {:error, :network_error, _reason}) do
    conn
    |> put_status(:bad_gateway)
    |> json(%{error: %{message: "Failed to reach LLM provider"}})
  end
end
