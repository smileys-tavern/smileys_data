defmodule SmileysData.Query.User.Bot do
  @moduledoc """
  Registered bots and their associated meta data handler.  Registered bots are automated users that Smileys permits to run
  periodic tasks.
  """

  require Ecto.Query

  alias SmileysData.{RegisteredBot, RegisteredBotMeta, Repo}

  @doc """
  Retrieve all registered bots up to a limit
  """
  def all(limit) do
  	RegisteredBot
      |> Ecto.Query.limit(^limit)
      |> Repo.all
  end

  @doc """
  Retrieve a single bots meta data
  """
  def meta(%RegisteredBot{name: name} = _bot) do
  	RegisteredBotMeta
  	  |> Ecto.Query.where(botname: ^name)
  	  |> Repo.all
  end
end