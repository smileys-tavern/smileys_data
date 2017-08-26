defmodule SmileysData.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias SmileysData.User

  require Logger


  def for_token(user = %User{}) do
  	{:ok, "User:#{user.id}"}
  end
  
  def for_token(_) do
  	Logger.debug "Unknown resource type for tokenization"
  	{:error, "Unknown resource type"}
  end

  def from_token("User:" <> id) do
  	{:ok, SmileysData.QueryUser.user_by_id(id)}
  end

  def from_token(_) do
  	Logger.debug "Unknown resource type from token"
  	{ :error, "Unknown resource type" }
  end
end