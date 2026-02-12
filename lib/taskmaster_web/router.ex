defmodule TaskmasterWeb.Router do
  use TaskmasterWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # NEW: pipeline that requires authentication
  pipeline :authenticated do
    plug(TaskmasterWeb.Plugs.Auth)
  end

  scope "/api", TaskmasterWeb do
    pipe_through(:api)

    scope "/auth" do
      post("/register", AuthController, :register)
      post("/login", AuthController, :login)
    end

    # Authenticated routes
    scope "/" do
      pipe_through(:authenticated)
      get("/auth/me", AuthController, :me)
      resources("/todos", TodoController, except: [:new, :edit])
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:taskmaster, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard", metrics: TaskmasterWeb.Telemetry)
    end
  end
end
