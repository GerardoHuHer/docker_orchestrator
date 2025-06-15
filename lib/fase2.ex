defmodule Fase2 do
  alias Fase1

  def crear_contenedor(
        img \\ "",
        nombre \\ "",
        env_variables \\ [],
        port \\ [],
        volumes \\ [],
        cmd \\ []
      ) do
    if img != "" do
      name_validation =
        case nombre do
          "" -> []
          _ -> ["--name", nombre]
        end

      ports = Enum.flat_map(port, fn p -> ["-p", p] end)

      variables_entorno =
        Enum.flat_map(env_variables, fn var ->
          ["-e", var]
        end)

      volumenes = Enum.flat_map(volumes, fn v -> ["-v", v] end)

      arguments =
        ["run"] ++
          name_validation ++ ports ++ variables_entorno ++ volumenes ++ ["-d", img] ++ cmd

      IO.inspect(arguments, label: "Comando Docker")

      case System.cmd("docker", arguments) do
        {_, 0} -> IO.puts("Container is running")
        {error, code} -> IO.puts("Error (#{code}): #{error}")
      end
    else
      IO.puts("No se ingresó una imagen")
    end
  end

  def ver_logs(id) do
    Fase1.container_exists(id)
  end
end
