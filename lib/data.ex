defmodule SmileysData.Data do
  @moduledoc """
  A module that keeps using definitions for models.

  This can be used in your application as:

      use SmileysData.Data, :model
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  @doc """
  When used, dispatch to the appropriate model/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end