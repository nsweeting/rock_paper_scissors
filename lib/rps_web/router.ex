defmodule RPSWeb.Router do
  use RPSWeb.Definitions, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {RPSWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :app do
    plug :authenticate
  end

  scope "/", RPSWeb do
    pipe_through :browser

    get "/signup", UserController, :new
    post "/signup", UserController, :create

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    get "/logout", SessionController, :delete
  end

  scope "/", RPSWeb do
    pipe_through :browser
    pipe_through :app

    live "/", LobbyLive
    live "/play", PlayLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", RPSWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: RPSWeb.Telemetry
    end
  end
end
