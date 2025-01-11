defmodule QserveIspApiWeb.Router do
  use QserveIspApiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {QserveIspApiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", QserveIspApiWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  scope "/api", QserveIspApiWeb do
    pipe_through [:api, QserveIspApiWeb.Plugs.Authenticate]
    get "/resource", ResourceController, :index
    resources "/nas", NasController, only: [:create]
    scope "/nas" do
      get "/certificates/:ip", NasController, :certificates
      get "/openvpnfiles/:ip", NasController, :openvpn_files

    end

  end

  scope "/api", QserveIspApiWeb do
    # Routes that do not require authentication
    pipe_through :api
    post "/login", AuthController, :login
    post "/register", AuthController, :register
    scope "/nas" do
     post "/radcheck", NasController, :insert_radcheck
    end

  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:qserve_isp_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: QserveIspApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
