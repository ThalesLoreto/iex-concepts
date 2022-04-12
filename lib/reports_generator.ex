defmodule ReportsGenerator do
  alias ReportsGenerator.Parser

  @available_foods [
    "açaí",
    "churrasco",
    "esfirra",
    "hambúrguer",
    "pastel",
    "pizza",
    "prato_feito",
    "sushi"
  ]

  @options ["foods", "users"]

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, acc -> sum_values(line, acc) end)
  end

  def build_from_many(filenames) when not is_list(filenames) do
    {:error, "Must be a list of filenames"}
  end

  def build_from_many(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, result}, acc -> sum_acc(result, acc) end)

    {:ok, result}
  end

  def fetch_higher_cost(report, option) when option in @options do
    {:ok, Enum.max_by(report[option], fn {_key, value} -> value end)}
  end

  def fetch_higher_cost(_report, _option), do: {:error, "Invalid option!"}

  defp sum_values([id, food_name, price], %{"users" => users, "foods" => foods}) do
    users = Map.put(users, id, users[id] + price)
    foods = Map.put(foods, food_name, foods[food_name] + 1)

    build_report(foods, users)
  end

  defp sum_acc(%{"foods" => foods_origin, "users" => users_origin}, %{
         "foods" => foods_acc,
         "users" => users_acc
       }) do
    foods = merge_maps(foods_origin, foods_acc)
    users = merge_maps(users_origin, users_acc)

    build_report(foods, users)
  end

  defp merge_maps(first_map, second_map) do
    Map.merge(first_map, second_map, fn _k, first_value, second_value ->
      first_value + second_value
    end)
  end

  defp report_acc() do
    foods = Enum.into(@available_foods, %{}, &{&1, 0})
    users = Enum.into(1..30, %{}, &{Integer.to_string(&1), 0})

    build_report(foods, users)
  end

  defp build_report(foods, users), do: %{"foods" => foods, "users" => users}
end
