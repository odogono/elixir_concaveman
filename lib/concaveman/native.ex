defmodule Concaveman.Native do
  @on_load :load_nif
  @nif_path "priv/#{Mix.target()}/lib/concaveman"

  defp load_nif do
    # :erlang.load_nif(~c"./priv/concaveman", 0)
    Application.app_dir(:concaveman, @nif_path)
    |> String.to_charlist()
    |> :erlang.load_nif(0)
  end

  # def concaveman2d(points, hull, concavity \\ 2.0, length_threshold \\ 0.0) do
  #   case concaveman(points, hull, concavity, length_threshold) do
  #     {:error, reason} -> raise "Failed to call concaveman NIF: #{reason}"
  #     result -> result
  #   end
  # end

  def concaveman(_points, _hull, _concavity, _length_threshold) do
    raise "NIF concaveman/4 not implemented"
  end
end
