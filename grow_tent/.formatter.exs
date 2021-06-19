[
  import_deps: [:ecto, :phoenix],
  inputs: [
    "*.{ex,exs}",
    "{lib,config,test}/**/*.{ex,exs}",
    "mix.exs"
  ],
  locals_without_parens: [
    transport: 2,
    action_fallback: 1,
    socket: 2,
    render: 2,
    field: 2,
    field: 3,

    # Plug
    plug: 1,
    plug: 2,
    forward: 3,

    # Formatter tests
    assert_format: 2,
    assert_format: 3,
    assert_same: 1,
    assert_same: 2,

    # Errors tests
    assert_eval_raise: 3,

    # Mix tests
    in_fixture: 2,
    in_tmp: 2,

    # Phoenix.
    pipe_through: 1,
    head: 3,
    get: 3,
    post: 3,
    patch: 3,
    put: 3,
    resources: 3,

    # Distillery
    set: 1
  ]
]
