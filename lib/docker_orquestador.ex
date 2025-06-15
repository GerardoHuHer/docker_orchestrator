defmodule DockerOrquestador do
  def hello do
    case System.cmd("echo", ["Hello, world"]) do
      {output, 0} -> IO.puts(output)
      {error_output, _} -> IO.puts(error_output)
    end
  end

  def lista_contenedores_activos() do
    case System.cmd("docker", ["ps", "--format", "{{.ID}}\t{{.Image}}\t{{.Names}}"]) do
      {salida, 0} ->
        salida
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(fn
          linea ->
            case String.split(linea, "\t") do
              [id, imagen, name] ->
                %{id: id, imagen: imagen, name: name}

              _ ->
                nil
            end
        end)

      {error_output, _code} ->
        IO.puts("Error al ejecutar docker ps: #{error_output}")
        []
    end
  end

  def lista_contenedores_detenidos() do
    case System.cmd("docker", [
           "ps",
           "-a",
           "--filter",
           "status=exited",
           "--format",
           "{{.ID}}\t{{.Image}}\t{{.Names}}"
         ]) do
      {salida, 0} ->
        salida
        |> String.trim()
        |> String.split("\n", trim: true)
        |> Enum.filter(fn linea -> String.trim(linea) != "" end)
        |> Enum.map(fn linea ->
          case String.split(linea, "\t") do
            [id, imagen, name] -> %{id: id, imagen: imagen, name: name}
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
    end
  end

  def contar_contenedores_activos() do
    lista_contenedores_activos() |> length()
  end

  def contar_contenedores_detenidos() do
    lista_contenedores_detenidos() |> length()
  end

  def imprimir_contenedores() do
    conts = lista_contenedores_activos()

    case conts do
      [nil] ->
        IO.puts("No hay contenedores activos que mostrar")

      _ ->
        IO.puts("| ID          | Imagen       | Nombre         |")
        IO.puts("|-------------|--------------|----------------|")

        Enum.each(conts, fn %{id: id, imagen: imagen, name: name} ->
          IO.puts(
            "| #{String.pad_trailing(id, 11)} | #{String.pad_trailing(imagen, 12)} | #{String.pad_trailing(name, 14)} |"
          )
        end)
    end
  end

  def imprimir_contenedores_detenidos() do
    conts = lista_contenedores_detenidos()

    case conts do
      [nil] ->
        IO.puts("No hay contenedores detenidos que mostrar")

      _ ->
        IO.puts("| ID          | Imagen       | Nombre         |")
        IO.puts("|-------------|--------------|----------------|")

        Enum.each(conts, fn %{id: id, imagen: imagen, name: name} ->
          IO.puts(
            "| #{String.pad_trailing(id, 11)} | #{String.pad_trailing(imagen, 12)} | #{String.pad_trailing(name, 14)} |"
          )
        end)
    end
  end

  def reiniciar_contenedor(id) do
    case container_exists(id) do
      %{id: id, name: _name, imagen: _imagen} ->
        case System.cmd("docker", ["restart", id]) do
          {_, 0} -> IO.puts("Contenedor #{id} se ha reiniciado exitosamente")
          {error, _} -> IO.puts("Error al reiniciar contenedor: #{error}")
        end

      nil ->
        IO.puts("El contenedor con el id #{id} no existe")
    end
  end

  def detener_contenedor(id) do
    case container_exists(id) do
      %{id: id, name: _name, imagen: _imagen} ->
        case System.cmd("docker", ["stop", id]) do
          {_, 0} -> IO.puts("Contenedor #{id} detenido exitosamente")
          {error, _} -> IO.puts("Hubo un error al detener el contenedor: #{error}")
        end

      nil ->
        IO.puts("El contenedor #{id} no existe.")
    end
  end

  def eliminar_contenedor(id) do
    case container_exists(id) do
      %{id: id, name: _name, imagen: _imagen} ->
        case System.cmd("docker", ["rm", id]) do
          {_, 0} -> IO.puts("Contenedor #{id} eliminado exitosamente")
          {error, _} -> IO.puts("Hubo un error al eliminar el contenedor: #{error}")
        end

      nil ->
        IO.puts("El contenedor #{id} no existe")
    end
  end

  def iniciar_contenedor(id) do
    case System.cmd("docker", ["start", id]) do
      {_, 0} -> IO.puts("Contenedor #{id} ejecutandose exitosamente")
      {error, _} -> IO.puts("Hubo un error al iniciar el contenedor: #{error}")
    end
  end

  def run_container(img) do
    case System.cmd("docker", ["run", "-d", img]) do
      {_, 0} -> IO.puts("Contenedor de #{img} corriendo correctamente")
      {error, _} -> IO.puts("No se pudo ejecutar el contenedor correctamente #{error}")
    end
  end

  def container_exists(id) do
    activos = lista_contenedores_activos()
    inactivos = lista_contenedores_detenidos()

    case activos do
      [nil] ->
        case inactivos do
          [nil] -> []
          _ -> Enum.find(inactivos, fn cont -> cont.id == id end)
        end

      _ ->
        case inactivos do
          [nil] ->
            []

          _ ->
            Enum.find(lista_contenedores_activos() ++ lista_contenedores_detenidos(), fn cont ->
              cont.id == id
            end)
        end
    end
  end

  def container_info(id) do
    case container_exists(id) do
      nil ->
        IO.puts("No existe el contenedor con el #{id}")

      %{id: id, imagen: imagen, name: name} ->
        IO.puts("ID: #{id}")
        IO.puts("Imagen: #{imagen}")
        IO.puts("Nombre: #{name}")
    end
  end

  def eliminar_contenedores_detenidos() do
    lista_contenedores_detenidos() |> Enum.each(fn %{id: id} -> eliminar_contenedor(id) end)
  end
end
