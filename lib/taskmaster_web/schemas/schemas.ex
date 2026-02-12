defmodule TaskmasterWeb.Schemas do
  alias OpenApiSpex.Schema

  # ── User ──

  defmodule User do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "User",
      type: :object,
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        email: %Schema{type: :string, format: :email},
        username: %Schema{type: :string},
        full_name: %Schema{type: :string, nullable: true},
        role: %Schema{type: :string, enum: ["admin", "member"]},
        active: %Schema{type: :boolean}
      },
      example: %{
        id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        email: "user@example.com",
        username: "johndoe",
        full_name: "John Doe",
        role: "member",
        active: true
      }
    })
  end

  defmodule RegisterRequest do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "RegisterRequest",
      type: :object,
      required: [:email, :username, :password],
      properties: %{
        email: %Schema{type: :string, format: :email},
        username: %Schema{type: :string, minLength: 3, maxLength: 100},
        password: %Schema{type: :string, minLength: 8},
        full_name: %Schema{type: :string}
      },
      example: %{
        email: "user@example.com",
        username: "johndoe",
        password: "Password123",
        full_name: "John Doe"
      }
    })
  end

  defmodule LoginRequest do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "LoginRequest",
      type: :object,
      required: [:email, :password],
      properties: %{
        email: %Schema{type: :string, format: :email},
        password: %Schema{type: :string}
      },
      example: %{email: "user@example.com", password: "Password123"}
    })
  end

  defmodule AuthResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "AuthResponse",
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          properties: %{
            user: User,
            token: %Schema{type: :string}
          }
        }
      }
    })
  end

  defmodule UserResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "UserResponse",
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          properties: %{
            user: User
          }
        }
      }
    })
  end

  # ── Todo ──

  defmodule Todo do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Todo",
      type: :object,
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        title: %Schema{type: :string},
        description: %Schema{type: :string, nullable: true},
        completed: %Schema{type: :boolean},
        user_id: %Schema{type: :string, format: :uuid}
      },
      example: %{
        id: "b1c2d3e4-f5a6-7890-bcde-f12345678901",
        title: "Buy groceries",
        description: "Milk, eggs, bread",
        completed: false,
        user_id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
      }
    })
  end

  defmodule CreateTodoRequest do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "CreateTodoRequest",
      type: :object,
      required: [:title],
      properties: %{
        title: %Schema{type: :string, minLength: 1, maxLength: 40},
        description: %Schema{type: :string, maxLength: 100},
        completed: %Schema{type: :boolean, default: false}
      },
      example: %{title: "Buy groceries", description: "Milk, eggs, bread"}
    })
  end

  defmodule UpdateTodoRequest do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "UpdateTodoRequest",
      type: :object,
      properties: %{
        title: %Schema{type: :string, minLength: 1, maxLength: 40},
        description: %Schema{type: :string, maxLength: 100},
        completed: %Schema{type: :boolean}
      },
      example: %{completed: true}
    })
  end

  defmodule TodoResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "TodoResponse",
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          properties: %{
            todo: Todo
          }
        }
      }
    })
  end

  defmodule TodoListResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "TodoListResponse",
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          properties: %{
            todos: %Schema{type: :array, items: Todo}
          }
        }
      }
    })
  end

  # ── Health ──

  defmodule HealthResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "HealthResponse",
      type: :object,
      properties: %{
        status: %Schema{type: :string, example: "ok"},
        app: %Schema{type: :string, example: "taskmaster"},
        version: %Schema{type: :string, example: "0.1.0"},
        timestamp: %Schema{type: :string, format: :"date-time"}
      }
    })
  end

  # ── Errors ──

  defmodule ErrorResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "ErrorResponse",
      type: :object,
      properties: %{
        error: %Schema{type: :string}
      },
      example: %{error: "Missing or invalid token"}
    })
  end

  defmodule ValidationErrorResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "ValidationErrorResponse",
      type: :object,
      properties: %{
        errors: %Schema{type: :object, additionalProperties: true}
      },
      example: %{errors: %{email: ["has already been taken"]}}
    })
  end
end
