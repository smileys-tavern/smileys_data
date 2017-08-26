defprotocol SmileysData.Protocols.MetaProtocol do
  use SmileysData.Data, :model

  @fallback_to_any true

  @doc """
  Create a meta struct or return an error reason if the data is invalid. If sent a list of values and names
  they must be of equal length and will return a list of tuple results.
  """
  def create(value, name)

  @doc """
  Check a name to see if it is valid as a meta name and return a tuple indicating an error
  and reason, or :ok and the name.
  """
  def check_name(name)

  @doc """
  Return the value type of a meta struct 
  """
  def check_value_type(meta)

  @doc """
  Return a meta value from a meta or sets of meta
  """
  def get_meta_value(meta)
  def get_meta_value(meta, key)

  @doc """
  Return a meta transformation from %Meta to a list of equality statements mapped from the meta names and values
  """
  def get_meta_statements(meta)
end

defimpl SmileysData.Protocols.MetaProtocol, for: BitString do
  alias SmileysData.Structs.Meta

  def check_name(name) do
    cond do
      String.length(name) > 40 ->
        {:error, "Graph entity meta can only be 40 characters or fewer long"}
      String.match?(name, ~r/^[a-zA-Z]+$/) == false ->
        {:error, "Graph entity meta can only include upper and lower case letters"}
      true ->
        {:ok, name}
    end
  end

  def create(value, name) do
    case SmileysData.Protocols.MetaProtocol.check_name(name) do
      {:error, reason} ->
        {:error, reason}
      {:ok, valid_name} ->
        cond do
          String.length(value) > 80 ->
            {:error, "Graph Meta value can only be 80 characters or fewer long"}
          String.match?(value, ~r/^[a-zA-Z][a-zA-Z0-9 ]/) == false ->
            {:error, "Graph Meta string value must start with a letter and only contain letters, numbers and spaces"}
          true ->
            {:ok, %Meta{name: valid_name, value: value}}
        end
    end
  end

  def check_value_type(_) do
    :string
  end
end

defimpl SmileysData.Protocols.MetaProtocol, for: Integer do
  alias SmileysData.Structs.Meta

  def create(value, name) do
    case SmileysData.Protocols.MetaProtocol.check_name(name) do
      {:error, reason} ->
        {:error, reason}
      {:ok, valid_name} ->
        {:ok, %Meta{name: valid_name, value: value}}
    end
  end

  def check_value_type(_) do
    :integer
  end
end

defimpl SmileysData.Protocols.MetaProtocol, for: List do
  alias SmileysData.Structs.Meta

  def get_meta_value([meta = %Meta{}|tail], key) do
    case meta.name do
      key ->
        {:ok, meta.value}
      _ ->
        SmileysData.Protocols.MetaProtocol.get_meta_value(tail, key)
    end
  end

  def get_meta_value([], _) do
    {:error, "Key not found while trying to retrieve graph entity meta"}
  end

  def create(values_list = [first_value|tail_values], names_list = [first_name|tail_names]) do
    cond do
      length(values_list) == length(names_list) ->
        [SmileysData.Protocols.MetaProtocol.create(first_value, first_name)|SmileysData.Protocols.MetaProtocol.create(tail_values, tail_names)]
      true ->
        {:error, "Lists of meta can only be created on matching lists of names and values of equal length"}
    end
  end

  def create([], _) do
    []
  end

  def get_meta_statements(metas) do
    Enum.reduce(metas, [], fn(%{name: n, value: v}, acc) -> 
      case SmileysData.Protocols.MetaProtocol.check_value_type(v) do
        :integer ->
          [(n <> " = '" <> Integer.to_string(v) <> "'")|acc]
        :string ->
          [(n <> " = '" <> v <> "'")|acc]
        :invalid ->
          acc
      end
    end)
  end
end

defimpl SmileysData.Protocols.MetaProtocol, for: Meta do
  alias SmileysData.Structs.Meta

  def get_meta_value(%Meta{value: value}) do
    {:ok, value}
  end

  def get_meta_statements(meta = %Meta{name: name, value: value}) do
    case SmileysData.Protocols.MetaProtocol.check_value_type(value) do
      :integer ->
        [(name <> " = '" <> Integer.to_string(value) <> "'")]
      :string ->
        [(name <> " = '" <> value <> "'")]
      :invalid ->
        []
    end
  end

  def check_value_type(%Meta{value: value}) do
    SmileysData.Protocols.MetaProtocol.check_value_type(value)
  end
end

defimpl SmileysData.Protocols.MetaProtocol, for: Any do
  alias SmileysData.Structs.Meta

  def check_name(_) do
    {:error, "Graph entity meta names need to be a string"}
  end

  def create(_, _) do
    {:error, "Graph Meta values can be only strings or integers"}
  end

  def check_value_type(_) do
    :invalid
  end

  def get_meta_value(_) do
    {:error, }
  end
end