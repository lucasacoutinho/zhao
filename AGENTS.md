# Using Zhao

Zhao builds command-line interfaces in Bend 2.0.16. Use its command builders
for flags, arguments, subcommands, help, and version output. Keep application
behavior in the handler. Read `bend guide` before writing Bend code.

## Import the package

```bend
import Base
import 0x64a14ed3ebe66ae2700afc3c3bafd113/zhao.bend as Z
```

Bend downloads and verifies this immutable package on the first run. When
working inside Zhao's repository, examples import `../src/zhao.bend` instead.
There are no runtime dependencies beyond Base.

## Define a command and its handler

Each builder returns a new `Z.Command`; rebind `cmd` as you add options and
arguments. This is a complete application:

```bend
import Base
import 0x64a14ed3ebe66ae2700afc3c3bafd113/zhao.bend as Z

def program() -> Z.Command:
  cmd = Z.command("pack")
  cmd = Z.description(cmd, "Choose files and an output directory")
  cmd = Z.version(cmd, "1.0.0")
  cmd = Z.option_default(cmd, "-o, --output <path>", "Output directory", "dist")
  Z.argument(cmd, "<files...>", "Files to pack")

def execute(input: Z.Invocation) -> IO(Unit):
  +invocation = input
  files = Z.value.many(Z.arg(invocation, "files"))
  output = Z.value.text(Z.get(invocation, "output"), "dist")
  IO.print(String.join(files, ", ") ++ " -> " ++ output)

def main() -> IO(Unit):
  Z.run(program(), execute)
```

Save it as `pack.bend` and run:

```sh
bend pack.bend -- one two --output build
# one, two -> build
bend pack.bend -- --help
```

For a native binary, run `bend pack.bend -o pack`, then
`./pack -- one two --output build`. The first `--` separates Bend runtime
options from your application's arguments.

The handler must have type `Z.Invocation -> IO(Unit)`. Keep its parameter
affine, as above; bind a reusable local with `+invocation = input` when reading
multiple fields.

## Choose declarations and read values

| Declaration | Meaning | Read with |
| --- | --- | --- |
| `Z.option(cmd, "-v, --verbose", "...")` | Boolean flag, absent when omitted | `Z.value.enabled(Z.get(input, "verbose"))` |
| `Z.option(cmd, "--no-color", "...")` | True by default, false when supplied | `Z.value.enabled(Z.get(input, "color"))` |
| `Z.option(cmd, "--port <number>", "...")` | Option whose value is required when supplied | `Z.value.text(Z.get(input, "port"), "")` |
| `Z.required_option(cmd, "--token <value>", "...")` | Option that must appear | `Z.value.text(Z.get(input, "token"), "")` |
| `Z.option(cmd, "--color [name]", "...")` | Optional value: boolean true when supplied alone, text with a value | Match `Z.get(input, "color")` |
| `Z.argument(cmd, "<file>", "...")` | Required positional argument | `Z.value.text(Z.arg(input, "file"), "")` |
| `Z.argument(cmd, "[file]", "...")` | Optional positional argument | `Z.value.text(Z.arg(input, "file"), "fallback")` |
| `Z.argument(cmd, "<files...>", "...")` | One or more positional arguments | `Z.value.many(Z.arg(input, "files"))` |
| `Z.argument(cmd, "[files...]", "...")` | Zero or more positional arguments | `Z.value.many(Z.arg(input, "files"))` |

Use `option_default` for a string default on a value-taking option and
`argument_default` for a positional default. Option keys come from the long
flag in camel case: `--dry-run` becomes `dryRun`, and `--no-color` becomes
`color`. Option and argument keys occupy separate namespaces.

`get` and `arg` return `Maybe<&2, Z.Value>`. Match `None{}`,
`Some{Z.Boolean{value}}`, `Some{Z.Text{value}}`, or `Some{Z.Many{values}}` when
absence or the value type matters. Convert strings and validate domain rules
in application code; Zhao does not parse numbers or enforce choices.

## Compose subcommands

Build a child with `Z.command`, configure it, optionally call
`Z.alias(child, "p")`, and attach it with `Z.subcommand(parent, child)`.
Dispatch inside the handler using `Z.path(input)`, which returns canonical
names including the root. An alias selects its canonical command name.

Parent options work before and after child commands. Flags and keys must be
unique along a command path. A command either groups subcommands or accepts
positional arguments. See `examples/forge.bend` for nested commands and
inherited options.

## Handle parsing and output

Use `Z.run(program(), handler)` for the standard behavior: print help or
version, exit 1 on a parser error, or call the handler. For a custom exit policy
or integration with another runtime, call `Z.parse(cmd, argv)` with only the
application tokens and match its result:

- `Z.Parsed{invocation}`: perform application work.
- `Z.Help{text}`: display the generated help.
- `Z.Version{text}`: display the version.
- `Z.Error{code, message}`: handle the parser error with your own exit policy.

`Z.dispatch(outcome, handler)` applies the standard IO behavior to an existing
outcome. `Z.help(cmd)` renders root help without parsing or IO.

## Respect parsing rules

- Options need a long name; a one-letter short alias is optional.
- Repeated scalar options keep the last value. Zhao does not collect repeated
  option values into a list.
- Required-value options consume the next token even if it starts with `-`.
  Optional values consume non-options or negative numbers; use `--color=-x`
  for another dashed value.
- `--` ends option parsing. Required positional arguments precede optional
  ones, and a variadic argument must be last.
- Help and version stop parsing when encountered. Earlier errors win; later
  tokens are ignored. Version flags are enabled per command, not inherited.
- Do not assume full Commander.js compatibility. Short-only flags, variadic
  options, hooks, environment options, conflicts, and custom value parsers
  are not implemented.

## Working on this repository

The public implementation is `src/zhao.bend`; text helpers are in
`src/text.bend`. Keep requirements in `src/LAWS.bend` and proofs in
`src/PROOF.bend`. Only `src/` is packaged for Bendhub.

Run `make setup`, `make check`, and `make package`. Run the proof entry point
before committing: `.tools/bend/bin/bend src/PROOF.bend`. Preserve pure parsing
and put IO in the adapter or application handler.

This bootstrap repository excludes tests and testing dependencies. Do not add
or publish a test suite until explicitly requested. `make publish` uploads the
package; ordinary checks do not publish.
