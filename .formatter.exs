locals_without_parens = [
  absinthe_field_telemetry_dashboard: 1,
  absinthe_field_telemetry_dashboard: 2,
  test_backend: 1
]

[
  import_deps: [
    :absinthe,
    :phoenix,
    :typed_struct
  ],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [locals_without_parens: locals_without_parens],
  locals_without_parens: locals_without_parens,
  plugins: [Phoenix.LiveView.HTMLFormatter]
]
