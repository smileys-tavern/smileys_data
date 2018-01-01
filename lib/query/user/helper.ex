defmodule SmileysData.Query.User.Helper do
  @moduledoc """
  A module of helpful functionality related directly to users
  """

  @doc """
  Create a unique hash to represent a user by their ip
  """
  def create_hash(user_ip) do
  	# TODO: move salt to a config and change it
    s = Hashids.new([
      salt: "smileysuser-mystery",
      min_len: 6,
    ])

    Hashids.encode(s, Tuple.to_list(user_ip))
  end

  @doc """
  Return the permission set that applies to the passed User
  (Deprecated? Checked usages)
  """
  def permission_level(_user) do
    %{default: Guardian.Permissions.max}
  end
end