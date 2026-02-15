defmodule Beamclaw2Web.HealthControllerTest do
  use Beamclaw2Web.ConnCase, async: true

  describe "GET /health" do
    test "returns 200 with status ok", %{conn: conn} do
      conn = get(conn, "/health")

      assert json_response(conn, 200)["status"] == "ok"
    end

    test "returns ISO8601 timestamp", %{conn: conn} do
      conn = get(conn, "/health")

      body = json_response(conn, 200)
      assert {:ok, _dt, _offset} = DateTime.from_iso8601(body["timestamp"])
    end

    test "returns application/json content type", %{conn: conn} do
      conn = get(conn, "/health")

      assert {"content-type", content_type} =
               List.keyfind(conn.resp_headers, "content-type", 0)

      assert content_type =~ "application/json"
    end
  end
end
