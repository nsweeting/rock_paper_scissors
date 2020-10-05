defmodule RPS.Config do
  @moduledoc """
  Configuration for the RPS application.
  """

  ################################
  # Public API
  ################################

  @spec secrets_path(file :: binary()) :: binary()
  def secrets_path(file) do
    Application.app_dir(:rps) <> "/priv/secrets/#{file}"
  end
end
