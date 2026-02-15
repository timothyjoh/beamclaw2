defmodule Beamclaw2.LLM.MockHttpClient do
  @moduledoc """
  Mock HTTP client for testing LLM providers.
  Uses process dictionary to set expected responses per test.
  """

  @behaviour Beamclaw2.LLM.HttpClient

  def set_response(response) do
    Process.put(:mock_http_response, response)
  end

  def set_stream_response(response) do
    Process.put(:mock_http_stream_response, response)
  end

  @impl true
  def post(_url, _headers, _body) do
    case Process.get(:mock_http_response) do
      nil -> {:error, :no_mock_response}
      response -> response
    end
  end

  @impl true
  def post_stream(_url, _headers, _body) do
    case Process.get(:mock_http_stream_response) do
      nil -> {:error, :no_mock_response}
      response -> response
    end
  end
end
