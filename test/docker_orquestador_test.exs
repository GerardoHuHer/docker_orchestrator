defmodule DockerOrquestadorTest do
  use ExUnit.Case
  doctest DockerOrquestador

  test "greets the world" do
    assert DockerOrquestador.hello() == :world
  end
end
