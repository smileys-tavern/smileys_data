defmodule SmileysData.Query.User do

	require Ecto.Query
	
	alias SmileysData.{Repo, User}

	@doc """
	Return full user data after querying by email
	"""
	def by_email(email) do
		User |> Repo.get_by(email: email)
	end

	@doc """
	Return full user data after querying by name
	"""
	def by_name(user_name) do
		User |> Repo.get_by(name: user_name)
	end

	@doc """
	Return full user data after querying by id
	"""
	def by_id(user_id) do
		User |> Repo.get(user_id)
	end

	@doc """
  	Call this when voting on and against original content
 	 """
  	def update_reputation(post, adjustValue) do
		cond do
		    adjustValue >= 0 ->
		      Ecto.Query.from(u in User, 
		        where: u.id == ^post.posterid, where: u.reputation < 100, 
		        update: [inc: [reputation: ^adjustValue]]
		      ) |> Repo.update_all([])
		    true ->
		      Ecto.Query.from(u in User, 
		        where: u.id == ^post.posterid, where: u.reputation > 0, 
		        update: [inc: [reputation: ^adjustValue]]
		) |> Repo.update_all([])
		end
	end
end