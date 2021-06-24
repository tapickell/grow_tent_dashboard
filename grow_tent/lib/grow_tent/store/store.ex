defmodule GrowTent.Store.Store do
  use GrowTent.Store.Macros

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

  def all_with_values(table) when is_atom(table) do
    catch_error do
      catch_table_not_found table do
        allmodules =
          [GrowTent.M709001A.SlotDefs, GrowTent.M709003B.SlotDefs, GrowTent.M715002A.SlotDefs, GrowTent.M718030A.SlotDefs]
          |> Enum.map(fn mod ->
            :ets.lookup(table, mod)
          end)
          |> List.flatten()
          |> Enum.map(fn {module, table} ->
            {module, GrowTent.EnumHelper.set_values(table, module)}
          end)

        {:ok, allmodules}
      end
    end
  end

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
