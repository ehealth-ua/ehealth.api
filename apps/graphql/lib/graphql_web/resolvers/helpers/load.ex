defmodule GraphQLWeb.Resolvers.Helpers.Load do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      import Absinthe.Resolution.Helpers, only: [on_load: 2]

      @type dataloader_tuple :: {:middleware, Absinthe.Middleware.Dataloader, term}
      @type key_function ::
              (Absinthe.Resolution.source(), Absinthe.Resolution.arguments(), Absinthe.Resolution.t() ->
                 {Dataloader.source_name(), params :: map})
      @type load_opt :: {:key, map} | {:args, map}

      @spec load_by_args(Dataloader.source_name(), key_function | any, [load_opt]) ::
              Absinthe.Resolution.Helpers.dataloader_tuple()
      def load_by_args(source, fun, opts \\ [])

      def load_by_args(source, fun, opts) when is_function(fun, 3) or is_function(fun, 2) do
        fn parent, args, %{context: %{loader: loader}} = res ->
          with key <- Keyword.get(opts, :key, :id),
               {:ok, item_key} <- Map.fetch(args, key),
               {resource, args} <- apply_key_function(fun, parent, args, res),
               params <- get_params(args, opts) do
            do_load(loader, source, resource, params, item_key)
          end
        end
      end

      def load_by_args(source, resource, opts) do
        fn args, %{context: %{loader: loader}} ->
          with key <- Keyword.get(opts, :key, :id),
               {:ok, item_key} <- Map.fetch(args, key),
               params <- get_params(args, opts) do
            do_load(loader, source, resource, params, item_key)
          end
        end
      end

      @spec load_by_parent(Dataloader.source_name(), key_function | any, [load_opt]) ::
              Absinthe.Resolution.Helpers.dataloader_tuple()
      def load_by_parent(source, fun, opts \\ [])

      def load_by_parent(source, fun, opts) when is_function(fun, 3) or is_function(fun, 2) do
        fn parent, args, %{context: %{loader: loader}} = res ->
          with key <- get_parent_key(parent, res.definition.schema_node.identifier, opts),
               {:ok, item_keys} <- Map.fetch(parent, key),
               {resource, args} <- apply_key_function(fun, parent, args, res),
               params <- get_params(args, opts) do
            do_load(loader, source, resource, params, item_keys)
          end
        end
      end

      def load_by_parent(source, resource, opts) do
        fn parent, args, %{context: %{loader: loader}} = res ->
          with key <- get_parent_key(parent, res.definition.schema_node.identifier, opts),
               {:ok, item_keys} <- Map.fetch(parent, key),
               params <- get_params(args, opts) do
            do_load(loader, source, resource, params, item_keys)
          end
        end
      end

      defp apply_key_function(fun, parent, args, res) when is_function(fun, 3), do: fun.(parent, args, res)

      defp apply_key_function(fun, _, args, res) when is_function(fun, 2), do: fun.(args, res)

      defp get_parent_key(parent, identifier, opts) do
        cond do
          Keyword.has_key?(opts, :key) -> Keyword.get(opts, :key)
          Map.has_key?(parent, :"#{identifier}_id") -> :"#{identifier}_id"
          Map.has_key?(parent, identifier) -> identifier
          true -> nil
        end
      end

      defp get_params(args, opts) do
        opts
        |> Keyword.get(:params, %{})
        |> Map.merge(args)
      end

      defp do_load(loader, source, resource, params, item_keys) when is_list(item_keys) do
        loader
        |> Dataloader.load_many(source, {resource, params}, item_keys)
        |> on_load(&{:ok, Dataloader.get_many(&1, source, {resource, params}, item_keys)})
      end

      defp do_load(loader, source, resource, params, item_key) do
        loader
        |> Dataloader.load(source, {resource, params}, item_key)
        |> on_load(&{:ok, Dataloader.get(&1, source, {resource, params}, item_key)})
      end
    end
  end
end
