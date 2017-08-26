defprotocol SmileysData.Protocols.GraphDocument do
	@fallback_to_any true

	@doc """
	Retrieve a graph entity id from graph inputs such as marco polo documents
	"""
	def get_doc_id(document)

	@doc """
	Transform arguments into a unique graph document id
	"""
	def to_doc_id(id_string)
	def to_doc_id(cluster_id, position)

	@doc """
	Retrieve the class name from a graph document
	"""
	def get_class(document)

	@doc """
	Return the custom fields from a graph document
	"""
	def get_fields(document)

	@doc """
	Return a string in the RID format from a generic smileys graph id string
	"""
	def doc_id_to_rid(doc_id)
end

defimpl SmileysData.Protocols.GraphDocument, for: MarcoPolo.Document do
	def get_doc_id(%MarcoPolo.Document{rid: %MarcoPolo.RID{cluster_id: cid, position: p}}) do
		{:ok, Integer.to_string(cid) <> "_" <> Integer.to_string(p)}
	end

	def get_doc_id(_) do
		{:error, "No ID set on MarcoPolo graph document"}
	end

	def to_doc_id(%MarcoPolo.Document{rid: %MarcoPolo.RID{} = rid}) do
		rid
	end

	def get_class(%MarcoPolo.Document{class: class}) do
		{:ok, class}
	end

	def get_class(_) do
		{:error, "No class set on MarcoPolo graph document"}
	end

	def get_fields(%MarcoPolo.Document{fields: fields}) do
		{:ok, fields}
	end

	def get_fields(_) do
		{:error, "No fields set on MarcoPolo graph document"}
	end
end

defimpl SmileysData.Protocols.GraphDocument, for: BitString do
	def to_doc_id(id_string) do
		case String.split(id_string, "_") do
			[cluster_id, position] ->
				{:ok, %MarcoPolo.RID{cluster_id: cluster_id, position: position}}
			_ ->
				{:error, "Format of string to MarcoPolo RID must be in the format cluster id and position separated by an underscore (_)"}
		end
	end

	def to_doc_id(cluster_id, position) do
		{:ok, %MarcoPolo.RID{cluster_id: cluster_id, position: position}}
	end

	def doc_id_to_rid(doc_id) do
		case String.split(doc_id, "_") do
			[cluster_id, position] ->
				"#" <> cluster_id <> ":" <> position
			_ ->
				nil
		end
	end
end

defimpl SmileysData.Protocols.GraphDocument, for: Any do
	def get_doc_id(poy) do
		{:error, "Unsupported graph document type. Currently supporting MarcoPolo"}
	end

	def get_class(_) do
		{:error, "Unsupported graph document type. Currently supporting MarcoPolo"}
	end

	def get_fields(_) do
		{:error, "Unsupported graph document type. Currently supporting MarcoPolo"}
	end
end