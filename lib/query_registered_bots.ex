defmodule SmileysData.QueryRegisteredBots do
  @moduledoc """
  Registered bots and their associated meta data handler.  Registered bots are automated users that Smileys permits to run
  periodic tasks.
  """

  require Ecto.Query

  alias SmileysData.{RegisteredBot, RegisteredBotMeta, Repo}

  @doc """
  Retrieve all registered bots up to a limit
  """
  def bots(limit) do
  	RegisteredBot
      |> Ecto.Query.limit(^limit)
      |> Repo.all
  end

  @doc """
  Retrieve a single bots meta data
  """
  def meta_by_bot(%RegisteredBot{} = bot) do
  	RegisteredBotMeta
  	  |> Ecto.Query.where(botname: ^bot.name)
  	  |> Repo.all
  end
end