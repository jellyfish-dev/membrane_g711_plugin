require Logger

alias Membrane.G711.Benchmark

for module <- [Benchmark.Encode, Benchmark.Decode] do
  Logger.info("Running #{inspect(module)}")
  Benchee.run(module.runs(), inputs: module.inputs())
  Logger.info("End of #{inspect(module)}")
end
