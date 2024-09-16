defmodule Concaveman do
  @moduledoc """
  Documentation for `Concaveman`.
  """

  # @on_load :load_nif
  # @nif_path "priv/#{Mix.target()}/lib/concaveman"

  # defp load_nif do
  #   Application.app_dir(:concaveman, @nif_path)
  #   |> String.to_charlist()
  #   |> :erlang.load_nif(0)
  # end

  # def concaveman2d(points, hull, concavity \\ 2.0, length_threshold \\ 0.0) do
  #   case Concaveman.Native.concaveman_nif(points, hull, concavity, length_threshold) do
  #     {:error, reason} -> raise "Failed to call concaveman NIF: #{reason}"
  #     result -> result
  #   end
  # end
end
