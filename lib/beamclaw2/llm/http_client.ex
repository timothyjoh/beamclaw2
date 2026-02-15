defmodule Beamclaw2.LLM.HttpClient do
  @moduledoc """
  Behaviour for HTTP client abstraction. Allows swapping implementations
  for testing (mock) vs production (Req).
  """

  @type response :: %{
          status: integer(),
          body: map() | binary(),
          headers: [{String.t(), String.t()}]
        }

  @callback post(url :: String.t(), headers :: [{String.t(), String.t()}], body :: map()) ::
              {:ok, response()} | {:error, term()}

  @callback post_stream(url :: String.t(), headers :: [{String.t(), String.t()}], body :: map()) ::
              {:ok, Enumerable.t()} | {:error, term()}
end
