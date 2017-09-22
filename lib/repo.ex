defmodule SmileysData.Repo do
  use Ecto.Repo, otp_app: :smileysdata
  use Kerosene, per_page: 30
end