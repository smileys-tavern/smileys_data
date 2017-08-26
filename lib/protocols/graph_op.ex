defprotocol SmileysData.Protocols.GraphOp do
  @fallback_to_any true

  @doc """
  Retrieve a query tuple including the operation type and query string based on the type of
  graph entity provided
  """
  def get_insert_query(graph_entity)

  @doc """
  Add meta data to a graph vertex or edge that would be included on inserts and updates
  """
  def add_meta(graph_entity, meta)
  def add_meta(graph_entity, name, value)

  @doc """
  Retrieve a query tuple including the operation type and query string based on type of graph
  entity provided
  """
  def get_select_query(graph_entity)
  def get_select_query(graph_entity, keys)

  @doc """
  Map into a %Vertex graph entity
  """
  def to_vertex(v)

  @doc """
  Map into an %Edge graph entity
  """
  def to_edge(e)

  @doc """
  Map into graph %Meta structure
  """
  def to_meta(m)
  def to_meta(m, acc)
end

defimpl SmileysData.Protocols.GraphOp, for: SmileysData.Structs.Vertex do
  alias SmileysData.Structs.Vertex
  alias SmileysData.Protocols.MetaProtocol

  def get_insert_query(%Vertex{class: class, meta: meta}) do

    meta = Enum.reduce(meta, [], fn(%{name: n, value: v}, acc) -> 
  	  case MetaProtocol.check_value_type(v) do
  	    :integer ->
  		  [(n <> " = '" <> Integer.to_string(v) <> "'")|acc]
  		:string ->
  		  [(n <> " = '" <> v <> "'")|acc]
  		:invalid ->
  		  acc
  		end
  	end)

    meta_string = Enum.join(meta, ", ")

  	query = cond do
  	  String.length(meta_string) > 0 ->
  	    "CREATE VERTEX " <> class <> " SET " <> meta_string
  	  true ->
  	  	"CREATE VERTEX " <> class
  	end

  	{:insert, query}
  end

  def get_select_query(%Vertex{id: id}) do
  	query = "SELECT FROM [" <> id <> "]"

  	{:select, query}
  end

  def get_select_query(%Vertex{class: class, meta: meta}, key) do
  	case MetaProtocol.get_meta_value(meta, key) do
  		{:ok, value} ->
  			query = "SELECT FROM " <> class <> " WHERE " <> key <> " = '" <> value <> "'"

  			{:select, query}
  		_ ->
  			{:error, "Error selecting a meta value using the provided key"}
  	end
  end

  def get_select_query(%Vertex{class: class, meta: meta}, keys) when is_list(keys) do
  	meta_statements = MetaProtocol.get_meta_statements(meta)

  	where_clause = Enum.join(meta_statements, " AND ")

  	query = "SELECT FROM " <> class <> " WHERE " <> where_clause

  	{:select, query}
  end

  def add_meta(v = %Vertex{}, name, value) do
  	meta = MetaProtocol.create(value, name)

	{:ok, %{v | :meta => meta}}
  end
end

defimpl SmileysData.Protocols.GraphOp, for: SmileysData.Structs.Edge do
  alias SmileysData.Structs.{Vertex, Edge}
  alias SmileysData.Protocols.{MetaProtocol, GraphDocument}

  def get_insert_query(%Edge{class: class, meta: meta}, v1 = %Vertex{id: nil}, v2 = %Vertex{id: nil}, keys1, keys2) do

  	meta_statements = MetaProtocol.get_meta_statements(meta)

    meta_string = Enum.join(meta_statements, ", ")

    # using 2 vertex select queries get a set of nodes to create edges on along with the edge(s) meta
  	query = "CREATE EDGE " <> class <> " FROM ( " <> SmileysData.Protocols.GraphOp.get_select_query(v1, keys1) <> " )
          TO ( " <> SmileysData.Protocols.GraphOp.get_select_query(v2, keys2) <> " ) SET " <> meta_string

  	{:insert, query}
  end

  def get_insert_query(%Edge{class: class, meta: meta, v1: %Vertex{id: id1}, v2: %Vertex{id: id2}}) do

  	meta_statements = MetaProtocol.get_meta_statements(meta)

    meta_string = Enum.join(meta_statements, ", ")

  	query = "CREATE EDGE " <> class <> " FROM " <> GraphDocument.doc_id_to_rid(id1) <> " TO " <> GraphDocument.doc_id_to_rid(id2) <> " SET " <> meta_string

  	{:insert, query}
  end

  def get_insert_query(%Edge{class: class, meta: meta}, %Vertex{id: id1}, %Vertex{id: id2}) do

  	meta_statements = MetaProtocol.get_meta_statements(meta)

    meta_string = Enum.join(meta_statements, ", ")

  	query = "CREATE EDGE " <> class <> " FROM " <> id1 <> " TO " <> id2 <> " SET " <> meta_string

  	{:insert, query}
  end

  def add_meta(graph_entity, name, value) do
  	meta = MetaProtocol.create(value, name)

	{:ok, %{graph_entity | :meta => meta}}
  end
end

defimpl SmileysData.Protocols.GraphOp, for: Map do
	alias SmileysData.Structs.{Vertex, Edge, Meta}

	def to_vertex(%{class: class} = v) do
		# get id
		id = case v do
			%{id: id} ->
				id
			_ ->
				nil
		end

		# get meta
		meta = case v do
			%{meta: meta} ->
				SmileysData.Protocols.GraphOp.to_meta(meta)
			_ ->
				[]
		end

		%Vertex{class: class, id: id, meta: meta}
	end

	def to_edge(%{class: class} = e) do
		id = case e do
			%{id: id} ->
				id
			_ ->
				nil
		end

		meta = case e do
			%{meta: meta} ->
				SmileysData.Protocols.GraphOp.to_meta(meta)
			_ ->
				[]
		end

		{v1, v2} = case e do
			%{v1: vertex_out, v2: vertex_in} ->
				{SmileysData.Protocols.GraphOp.to_vertex(vertex_out),SmileysData.Protocols.GraphOp.to_vertex(vertex_in)}
			_->
				{nil, nil}
		end

		%Edge{class: class, id: id, meta: meta, v1: v1, v2: v2}
	end

	def to_meta(fields) do

		Enum.map(fields, fn {k, v} -> 
			%Meta{name: k, value: v} 
		end)
	end
end

defimpl SmileysData.Protocols.GraphOp, for: List do
	alias SmileysData.Structs.{Meta}

    def to_meta(m) do
		to_meta(m, [])
	end

	def to_meta([%{name: name, value: value}|tail], acc) do
		to_meta(tail, [%Meta{name: name, value: value}|acc])
	end

	def to_meta([], acc) do
		acc
	end

	def to_vertex(vertices) do
		Enum.map(vertices, fn(doc) -> SmileysData.Protocols.GraphOp.to_vertex(doc) end)
	end

	def to_vertex(edges) do
		Enum.map(edges, fn(doc) -> SmileysData.Protocols.GraphOp.to_edge(doc) end)
	end
end

defimpl SmileysData.Protocols.GraphOp, for: MarcoPolo.Document do
	alias SmileysData.Protocols.GraphDocument
	alias SmileysData.Structs.Vertex

	def to_vertex(%MarcoPolo.Document{class: class, fields: fields} = doc) do
		id = case GraphDocument.get_doc_id(doc) do
			{:ok, vertex_id} ->
				vertex_id
			{:error, _} ->
				nil
		end

		%Vertex{class: class, id: id, meta: SmileysData.Protocols.GraphOp.to_meta(fields)}
	end
end

defimpl SmileysData.Protocols.GraphOp, for: Any do
  def get_insert_query(_), do: {:noop, nil}
end