defmodule SmileysData.QueryGraph do
	alias SmileysData.Protocols.{GraphOp, GraphDocument}
	alias SmileysData.Structs.{Edge, Vertex, Meta}
	alias SmileysData.Typespecs.Graph

	require Logger

	# TODO: ADD USER CLASS CONSTRAINTS

	def insert_vertex(%Vertex{} = v) do

		{:insert, query} = GraphOp.get_insert_query(v)

		case MarcoPolo.command(SmileysData.Graph, query) do
			{:ok, %{response: doc}} ->
			  GraphDocument.get_doc_id(doc)
			{:error, error} ->
			  {:error, error}
		end
	end

	def insert_edge(%Edge{} = e) do

		{:insert, query} = GraphOp.get_insert_query(e)

		case MarcoPolo.command(SmileysData.Graph, query) do
			{:ok, %{response: [doc]}} ->
			  GraphDocument.get_doc_id(doc)
			{:error, error} ->
			  {:error, error}
		end
	end

	@doc """
	Retrieve a vertex by it's id
	"""
	def get_vertex(id) do
		

	end

	@doc """
	Retrieve vertices of a class by selecting against supplied meta.
	"""
	def get_vertices(%Vertex{meta: [%{name: key}|_]} = v) do
		
		{:select, query} = GraphOp.get_select_query(v, key)

		case MarcoPolo.command(SmileysData.Graph, query) do
			{:ok, result} ->
				vertices = GraphOp.to_vertex(result.response)

				{:ok, vertices}
			{:error, error} ->
				{:error, error}
		end
	end

	@doc """
	Retrieve all edges that connect 2 vetices
	"""
	def get_edges(v1 = %Vertex{}, v2 = %Vertex{}) do
		
	end
end