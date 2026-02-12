defmodule TaskmasterWeb.ApiSpec do
  alias OpenApiSpex.{Info, OpenApi, Paths, Server, SecurityScheme}
  alias TaskmasterWeb.Router

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Taskmaster API",
        version: "1.0.0",
        description: "A Todo API built with Phoenix — learning Elixir step by step."
      },
      servers: [
        %Server{url: "https://taskmaster-elixir.fly.dev", description: "Production"},
        %Server{url: "http://localhost:4000", description: "Local development"}
      ],
      paths: Paths.from_router(Router),
      components: %OpenApiSpex.Components{
        securitySchemes: %{
          "bearerAuth" => %SecurityScheme{
            type: "http",
            scheme: "bearer",
            bearerFormat: "Phoenix.Token"
          }
        }
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
