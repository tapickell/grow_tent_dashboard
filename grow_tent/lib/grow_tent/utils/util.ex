defmodule GrowTent.Util do
  require Logger

  @endline "\n"
  @empty_str ""
  @cat "cat"
  @err "Error with CMD "
  @spc " "
  @ls "ls"
  @non_zero "NonZero"
  @error "Error"
  @spcr " :: "

  def tab2binary(table) do
    info =
      case :ets.info(table) do
        :undefined -> throw(RuntimeError)
        info -> info
      end

    terms = %{
      info: info,
      data: :ets.tab2list(table)
    }

    :erlang.term_to_binary(terms)
  end

  def binary2table(binary) do
    :erlang.binary_to_term(binary)
    # |> parse_terms()
  end

  # def parse_terms()

  def terms2bins([t | ts]), do: [:erlang.term_to_binary(t) | terms2bins(ts)] |> hd()
  def terms2bins([]), do: []

  def cat_file(file_path) do
    if File.exists?(file_path) do
      {:ok, resp} = sys_cmd(@cat, [file_path])
      resp |> hd()
    else
      :err_nofile
    end
  end

  def run_command(executable, args, options \\ []) do
    debug = Keyword.get(options, :debug, "recvd from System.cmd run")
    parallelism = Keyword.get(options, :parallelism, false)

    try do
      case System.cmd(executable, args, parallelism: parallelism) do
        {str, 0} ->
          # _ = Logger.debug(@output <> debug <> inspect(str) <> @spcr <> inspect(args))
          {:ok, str}

        {_str, code} ->
          _ = Logger.warn(@non_zero <> debug <> inspect(code) <> @spcr <> inspect(args))
          {:error, :non_zero_code}
      end
    rescue
      err ->
        _ = Logger.error(@error <> debug <> inspect(err) <> @spcr <> inspect(args))
        {:error, :non_zero_code}
    end
  end

  def monot_time_now do
    System.monotonic_time()
  end

  def time_diff_in_ms(event_time) do
    System.convert_time_unit(monot_time_now() - event_time, :native, :millisecond)
  end

  def put_lines({str, code}) when is_binary(str) and is_integer(code) do
    puts_lines(str)
  end

  def puts_lines({a, lines}) when is_atom(a) and is_list(lines) do
    put_lines(lines)
  end

  def puts_lines(lines) do
    Enum.each(lines, &IO.puts/1)
  end

  def ls_dir(dir_path) do
    {:ok, resp} = sys_cmd(@ls, [dir_path])
    resp
  end

  def list_dir(dir_path) do
    {:ok, resp} = sys_cmd(@ls, ["-l", dir_path])
    resp
  end

  def sys_cmd(cmd, params) do
    case System.cmd(cmd, params) do
      {str, 0} ->
        out = clean_output(str)
        {:ok, out}

      {err_lines, code} ->
        _ = Logger.error(@err <> cmd <> @spc <> inspect(code))

        clean_output(err_lines)
        |> Enum.each(fn err ->
          _ = Logger.error(inspect(err))
        end)

        :error
    end
  end

  defp clean_output(output) do
    output
    |> String.split(@endline)
    |> Enum.filter(&(&1 != @empty_str))
  end
end
