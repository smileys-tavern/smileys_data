defprotocol SmileysData.State.Activity do
  @moduledoc """
  Interface to adjusting state for rooms posts and users.  Managed the top level bucket operations, leaving
  the logic to manipulate bucket items to Bucket Agents.
  """

  @doc """
  Looks up an individual users bucket pid by username stored in `server`.

  Returns pid if the bucket exists, :undefined otherwise. This identifier can be used to update or
  retrieve items from a users bucket
  """  
  def lookup_bucket(activity)

  @doc """
  Retrieve the entire state from the bucket
  """
  def retrieve(activity)

  @doc """
  Retrieve a user bucket by pid. if :undefined passed bucket should be created
  """
  def retrieve_item(activity)

  @doc """
  Update a bucket with the values in activity.  The bucket itself may have different update behavior such as incrementing or
  overwriting. Returns bucket pid and activity tuple.
  """
  def update_item(activity)

  @doc """
  Reverse an activity action. Often used during timeout implementations when activities should only report within a certain time window
  """
  def remove_item(activity)

  @doc """
  Create a new bucket and add it to the activity supervisor
  """
  def create_bucket(activity)

  @doc """
  Helper method to create a consistent bucket name based on the activity
  """
  def get_bucket_name(activity)

end

  # UserActivity
  defimpl SmileysData.State.Activity, for: SmileysData.State.User.Activity do
  	alias SmileysData.State.UserActivitySupervisor
  	alias SmileysData.State.User.{Activity, ActivityBucket}
  
    def lookup_bucket(%Activity{} = activity) do
      case :syn.find_by_key(get_bucket_name(activity)) do
      	:undefined ->
      		create_bucket(activity)
      	pid ->
      		pid
      end
    end

    def retrieve(activity) do
      ActivityBucket.get_activity(lookup_bucket(activity))
    end

    def retrieve_item(activity) do
  	  ActivityBucket.get_activity(lookup_bucket(activity), activity)
  	end

  	def update_item(activity) do
    	ActivityBucket.add_new_activity(lookup_bucket(activity), activity)
  	end

    def remove_item(activity) do
      ActivityBucket.delete_activity(lookup_bucket(activity), activity)  
    end

  	def create_bucket(activity) do
      case UserActivitySupervisor.start_child(get_bucket_name(activity)) do
        {:ok, pid} ->
          pid
        _ ->
          :syn.find_by_key(get_bucket_name(activity))
      end
  	end

    def get_bucket_name(%Activity{user_name: user_name}) do
  	  "user_activity_" <> user_name
  	end
  end

  # UserNotification
  defimpl SmileysData.State.Activity, for: SmileysData.State.User.Notification do
  	alias SmileysData.State.UserActivitySupervisor
  	alias SmileysData.State.User.{Notification, ActivityBucket}
  
    def lookup_bucket(%Notification{} = activity) do
      case :syn.find_by_key(get_bucket_name(activity)) do
      	:undefined ->
      		create_bucket(activity)
      	pid ->
      		pid
      end
    end

    def retrieve(activity) do
      ActivityBucket.get_activity(lookup_bucket(activity))
    end

    def retrieve_item(activity) do
  	  ActivityBucket.get_activity(lookup_bucket(activity), activity)
  	end

	  def update_item(activity) do
  	  ActivityBucket.add_new_activity(lookup_bucket(activity), activity)
	  end

    def remove_item(activity) do
      ActivityBucket.delete_activity(lookup_bucket(activity), activity)
    end

	  def create_bucket(activity) do
      case UserActivitySupervisor.start_child(get_bucket_name(activity)) do
        {:ok, pid} ->
          pid
        _ ->
          :syn.find_by_key(get_bucket_name(activity))
      end
	  end

    def get_bucket_name(%Notification{user_name: user_name}) do
	    "user_activity_" <> user_name
	  end
  end

  # RoomActivity
  defimpl SmileysData.State.Activity, for: SmileysData.State.Room.Activity do
  	alias SmileysData.State.RoomActivitySupervisor
  	alias SmileysData.State.Room.{Activity, ActivityBucket}

  	def lookup_bucket(activity) do
  	  case :syn.find_by_key(get_bucket_name(activity)) do
  	  	:undefined ->
  	  		create_bucket(activity)
  	  	pid ->
  	  		pid
  	  end
  	end

  	# Single item bucket
  	def retrieve(activity) do
      retrieve_item(activity)
    end

  	def retrieve_item(activity) do
	    ActivityBucket.get_activity(lookup_bucket(activity))
	  end

	  def update_item(activity) do
	    ActivityBucket.increment_room_bucket_activity(lookup_bucket(activity), activity)
	  end

    def remove_item(%Activity{room: room, subs: subs, new_posts: new_posts, hot_posts: hot_posts} = activity) do
      ActivityBucket.increment_room_bucket_activity(lookup_bucket(activity), %Activity{room: room, subs: subs * -1, new_posts: new_posts * -1, hot_posts: hot_posts * -1}, :no_expire)
    end

	  def create_bucket(activity) do
	    case RoomActivitySupervisor.start_child(get_bucket_name(activity)) do
        {:ok, pid} ->
          pid
        _ ->
          :syn.find_by_key(get_bucket_name(activity))
      end
	  end

  	def get_bucket_name(%Activity{room: room_name}) do
  	  "room_activity_" <> room_name
  	end
  end

  # PostActivity
  defimpl SmileysData.State.Activity, for: SmileysData.State.Post.Activity do
  	alias SmileysData.State.PostActivitySupervisor
  	alias SmileysData.State.Post.{Activity, ActivityBucket}

  	def lookup_bucket(activity) do
  	  case :syn.find_by_key(get_bucket_name(activity)) do
  	  	:undefined ->
  	  		create_bucket(activity)
  	  	pid ->
  	  		pid
  	  end
  	end

  	# Single item bucket
    def retrieve(activity) do
      retrieve_item(activity)
    end

  	def retrieve_item(activity) do
	    ActivityBucket.get_activity(lookup_bucket(activity))
	  end

    def remove_item(%Activity{hash: hash, comments: comments} = activity) do
      ActivityBucket.increment_post_bucket_activity(lookup_bucket(activity), %Activity{hash: hash, comments: comments * -1})
    end

	  def update_item(activity) do
	    ActivityBucket.increment_post_bucket_activity(lookup_bucket(activity), activity)
	  end	

 	  def create_bucket(activity) do
	    case PostActivitySupervisor.start_child(get_bucket_name(activity)) do
        {:ok, pid} ->
          pid
        _ ->
          :syn.find_by_key(get_bucket_name(activity))
      end
	  end
 	
   	def get_bucket_name(%Activity{hash: hash}) do
  	  "post_activity_" <> hash
  	end 	
  end
