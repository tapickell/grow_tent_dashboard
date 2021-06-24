defmodule GrowTent.Record.Store do
  use GrowTent.Store.Macros

  # alias GrowTent.Record.{Config, Datetime, EnumStatus, Status}

  require Logger

  def storage_up(table) when is_atom(table) do
    catch_table_already_exists table do
      info =
        table
        |> :ets.new([:set, :public, :named_table])
        |> :ets.info()

      _ref = info[:id]
      {:ok, info}
    end
  end

  def storage_down(table) when is_atom(table) do
    catch_error do
      catch_write_protected table do
        catch_table_not_found table do
          true = :ets.delete(table)
          :ok
        end
      end
    end
  end

  def recreate_tables_with_data(tables_with_data, access \\ :public)
      when is_list(tables_with_data) and is_atom(access) do
    Enum.map(tables_with_data, fn {table_atom, data} ->
      recreate_table_with_data(table_atom, data, access)
    end)
  end

  def recreate_table_with_data(table, data, access \\ :public)
      when is_atom(table) and is_atom(access) do
    catch_error do
      catch_write_protected table do
        catch_table_not_found table do
          drop_table(table)
          :ets.new(table, [:set, access, :named_table])
          :ets.insert(table, data)
          :ok
        end
      end
    end
  end

  def table_snapshots(tables) when is_list(tables) do
    Enum.map(tables, fn table_atom ->
      table_snapshot(table_atom)
    end)
  end

  def table_snapshot(table) do
    catch_error do
      catch_table_not_found table do
        :ets.select(table, [{:"$1", [], [:"$1"]}])
      end
    end
  end

  def drop_tables(tables) do
    Enum.map(tables, fn table_atom ->
      drop_table(table_atom)
    end)
  end

  def drop_table(table) do
    catch_error do
      catch_table_not_found table do
        if :ets.whereis(table) != :undefined, do: :ets.delete(table)
      end
    end
  end

  def is_table?(table) when is_atom(table) do
    :ets.whereis(table) != :undefined
  end

  def load_table_from_file(table, file) do
    _ = Logger.info("Load table from file #{file} called")

    catch_error do
      catch_table_already_exists table do
        case File.read(file) do
          {:ok, zipped_file} ->
            binary_file = :zlib.gunzip(zipped_file)

            table_data =
              GrowTent.Util.binary2table(binary_file)
              |> Map.get(:data)

            {:ok, info} = storage_up(table)

            catch_table_not_found table do
              true = :ets.insert(table, table_data)
              {:ok, info}
            end

          {:error, error} ->
            _ = Logger.error("Unable to read from filesystem: #{error}")
            :ok
        end
      end
    end
  end

  def dump_table_to_file(table, file) do
    _ = Logger.info("Dump table to file #{file} called")

    catch_error do
      catch_table_not_found table do
        catch_read_protected table do
          zipped_file =
            GrowTent.Util.tab2binary(table)
            |> :zlib.gzip()

          case File.write(file, zipped_file, [:sync]) do
            :ok ->
              _ = Logger.warn("FILE WRITE WAS SUCCESSFUL #{file}")
              :ok

            {:error, error} ->
              _ = Logger.error("Unable to write to filesystem: #{error}")
              :ok
          end
        end
      end
    end
  end

  def insert(table, module, data) when is_atom(table) and is_atom(module) do
    # _ = Logger.info("Insert to table #{table} :: #{module} called")
    record = Keyword.put([], module, data)

    catch_error do
      catch_write_protected table do
        catch_records_too_small table, record do
          catch_bad_records record do
            catch_table_not_found table do
              true = :ets.insert(table, record)
              :ok
            end
          end
        end
      end
    end
  end

  def insert(table, record) when is_atom(table) and is_tuple(record) do
    # _ = Logger.info("Insert to table #{table} :: #{module} called")
    catch_error do
      catch_write_protected table do
        catch_record_too_small table, record do
          # catch_bad_record record do
          catch_table_not_found table do
            true = :ets.insert(table, record)
            :ok
          end

          # end
        end
      end
    end
  end

  def update_element(table, key, pv) when is_atom(table) and is_atom(key) do
    # _ = Logger.info("Insert to table #{table} :: #{module} called")
    catch_error do
      catch_write_protected table do
        catch_table_not_found table do
          true = :ets.update_element(table, key, pv)
          :ok
        end
      end
    end
  end

  # def all_with_values(table) when is_atom(table) do
  #   catch_error do
  #     catch_table_not_found table do
  #       allmodules =
  #         [GrowTent.M709001A.SlotDefs, GrowTent.M709003B.SlotDefs, GrowTent.M715002A.SlotDefs, GrowTent.M718030A.SlotDefs]
  #         |> Enum.map(fn mod ->
  #           :ets.lookup(table, mod)
  #         end)
  #         |> List.flatten()
  #         |> Enum.map(fn {module, table} ->
  #           {module, GrowTent.EnumHelper.set_values(table, module)}
  #         end)

  #       {:ok, allmodules}
  #     end
  #   end
  # end

  def all(table) when is_atom(table) do
    catch_error do
      catch_table_not_found table do
        {:ok, :ets.tab2list(table)}
      end
    end
  end

  def get(table, module) when is_atom(table) and is_atom(module) do
    catch_error do
      catch_read_protected table do
        catch_table_not_found table do
          data = :ets.lookup(table, module)

          {:ok, data}
        end
      end
    end
  end

  def get_element(table, module, element)
      when is_atom(table) and is_atom(module) and is_integer(element) do
    catch_error do
      catch_read_protected table do
        catch_table_not_found table do
          data = :ets.lookup_element(table, module, element)

          {:ok, data}
        end
      end
    end
  end

  def delete(table, module) when is_atom(table) and is_atom(module) do
    catch_error do
      catch_write_protected table do
        catch_table_not_found table do
          true = :ets.delete(table, module)
          :ok
        end
      end
    end
  end

  def has_key(table, module) do
    catch_error do
      catch_read_protected table do
        catch_table_not_found table do
          {:ok, :ets.member(table, module)}
        end
      end
    end
  end
end
