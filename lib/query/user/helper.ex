defmodule SmileysData.Query.User.Helper do
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