defmodule TaskmasterWeb.HealthController do
  use TaskmasterWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias TaskmasterWeb.Schemas

  tags(["Health"])

  operation(:index,
    summary: "Health check",
    description: "Returns the application status, version, and current timestamp.",
    responses: [
      ok: {"Health status", "application/json", Schemas.HealthResponse}
    ]
  )

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
      status: "ok",
      app: "taskmaster",
      version: Application.spec(:taskmaster, :vsn) |> to_string(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end
end
