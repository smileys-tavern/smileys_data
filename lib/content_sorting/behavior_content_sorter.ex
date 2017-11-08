defmodule SmileysData.ContentSorting.ContentSorterBehaviour do
  alias SmileysData.ContentSorting.SortSettings
  alias SmileysData.{User, Room, Post}

  # Adjustments directly to post vote score
  @callback decay_posts_new() :: {:ok, number} | {:error, String.t}
  
  @callback decay_posts_medium() :: {:ok, number} | {:error, String.t}

  @callback decay_posts_long() :: {:ok, number} | {:error, String.t}

  @callback decay_posts_termination() :: {:ok, number} | {:error, String.t}

  @callback get_settings() :: %SortSettings{}

  # Adjustments to entities that strengthen or weaken the individual vote contracts
  # TODO: refactor these two. too awkward and useless as a behavior
  @callback user_adjust(%Post{}, %User{}, %Room{}, number) :: :ok | {:error, String.t}

  @callback room_adjust(%Post{}, %User{}, %Room{}, number) :: :ok | {:error, String.t}

end