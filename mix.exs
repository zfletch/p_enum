defmodule PEnum.MixProject do
  use Mix.Project

  def project do
    [
      app: :p_enum,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description() do
    "Parallel Enum. This library provides a set of functions similar to the ones in the Enum module except that the function argument is executed on each element in parallel."
  end

  defp package() do
    [
      maintainers: ["zfletch"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/zfletch/p_enum"}
    ]
  end
end
