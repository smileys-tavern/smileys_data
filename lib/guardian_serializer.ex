defmodule SmileysData.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias SmileysData.User
  alias SmileysData.Query.User, as: QueryUser

  require Logger


  def for_token(user = %User{}) do
  	{:ok, "User:#{user.id}"}
  end
  
  def for_token(_) do
  	Logger.debug "Unknown resource type for tokenization"
  	{:error, "Unknown resource type"}
  end

  def from_token("User:" <> id) do
  	{:ok, QueryUser.by_id(id)}
  end

  def from_token(_) do
  	Logger.debug "Unknown resource type from token"
  	{ :error, "Unknown resource type" }
  end
end