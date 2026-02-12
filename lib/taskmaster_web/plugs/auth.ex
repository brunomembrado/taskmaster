defmodule TaskmasterWeb.Plugs.Auth do
    @moduledoc """
    Authentication plug — the Elixir equivalent of Express auth middleware.

    Express:  (req, res, next) => { req.user = decoded; next(); }
    Phoenix:  def call(conn, _opts), do: assign(conn, :current_user, user)
    """
    import Plug.Conn
    import Phoenix.Controller

    alias Taskmaster.Accounts

    # Every plug needs init/1 — it receives compile-time options.
    # Express has no equivalent — middleware doesn't have a compile step.
    def init(opts), do: opts

    # call/2 is like the middleware function itself.
    # It receives the conn (like req+res combined) and must return a conn.
    def call(conn, _opts) do
      with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
           {:ok, user_id} <- Phoenix.Token.verify(conn, "user_auth", token, max_age: 86400),
           {:ok, user} <- Accounts.get_user(user_id) do
        # This is like: req.user = user
        assign(conn, :current_user, user)
      else
        _ ->
          conn
          |> put_status(:unauthorized)
          |> json(%{error: "Missing or invalid token"})
          |> halt()  # ← CRITICAL: halt() stops the pipeline. Without it, the controller still runs!
      end
    end
  end
