# Zhao

Command-line interfaces for Bend. Define commands, options, and arguments as immutable data; Zhao parses the tokens, generates help, and passes the selected command to your handler. Parsing is pure, and process output and exits live in the IO adapter.

Zhao is a bootstrap release targeting Bend 2.0.16. It follows [Commander.js](https://github.com/tj/commander.js) conventions and has no runtime dependencies beyond Bend Base.

## What you get

- **Command builders.** Options, positional arguments, defaults, required values, nested commands, and aliases compose into one command definition.
- **Predictable parsing.** Short flags can be grouped, values can be attached, parent options work before and after subcommands, and `--` ends option parsing.
- **Generated help.** Usage, arguments, options, defaults, and subcommands come from the command definition.
- **Explicit outcomes.** `parse` returns `Parsed`, `Help`, `Version`, or `Error`. Applications can handle them directly or use `run` for the standard IO behavior.
- **Laws with proofs.** The package includes 11 stated rules and their proofs, alongside the parser.

## Quick start

Import Zhao directly from Bendhub. Bend downloads and verifies the package on the first run:

```bend
import Base
import 0x64a14ed3ebe66ae2700afc3c3bafd113/zhao.bend as Z

def program() -> Z.Command:
  cmd = Z.command("hello")
  cmd = Z.description(cmd, "Greet someone")
  cmd = Z.version(cmd, "1.0.0")
  cmd = Z.option(cmd, "-l, --loud", "Use uppercase")
  Z.argument(cmd, "<name>", "Person to greet")

def greeting(loud: Bool, name: String) -> String:
  match loud:
    case True{}:
      String.to_upper("Hello, " ++ name ++ "!")
    case False{}:
      "Hello, " ++ name ++ "!"

def greet(input: Z.Invocation) -> IO(Unit):
  +invocation = input
  IO.print(greeting(
    Z.value.enabled(Z.get(invocation, "loud")),
    Z.value.text(Z.arg(invocation, "name"), "")
  ))

def main() -> IO(Unit):
  Z.run(program(), greet)
```

Save this as `hello.bend`, then run it with application arguments after Bend's separator:

```sh
bend hello.bend -- Lucas --loud
# HELLO, LUCAS!
bend hello.bend -- --help
```

Compiled binaries use the same separator to distinguish Bend runtime flags from application flags:

```sh
bend hello.bend -o hello
./hello -- Lucas --loud
```

The repository's [greet](examples/greet.bend) and [forge](examples/forge.bend) examples cover defaults, nested commands, aliases, and inherited options. For vendoring, copy the contents of `src/` into `vendor/zhao/` and import `./vendor/zhao/zhao.bend` instead.

## How it fits together

Each builder returns a new `Command`. Rebind `cmd` as you add its pieces:

| Builder | Purpose |
| --- | --- |
| `command(name)` | Create a command |
| `description(cmd, text)` | Set help text |
| `version(cmd, text)` | Enable `-V, --version` |
| `alias(cmd, name)` | Give a subcommand another spelling |
| `option(cmd, flags, description)` | Add an option |
| `option_default(cmd, flags, description, value)` | Set a string default for a value-taking option |
| `required_option(cmd, flags, description)` | Require an option |
| `argument(cmd, syntax, description)` | Add a positional argument |
| `argument_default(cmd, syntax, description, value)` | Set a positional default |
| `subcommand(parent, child)` | Attach a command |

Options require a long name and may have a one-letter short alias. `--verbose` is a boolean flag, `--no-color` defaults to true and sets false when supplied, `--port <number>` takes a required value, and `--color [name]` takes an optional value. Values stay strings; applications convert and validate domain values.

Arguments use `<required>`, `[optional]`, `<many...>`, or `[many...]` syntax. Required arguments precede optional ones, and a variadic argument comes last.

- **Values.** `get(input, key)` reads an option; `arg(input, key)` reads an argument. Both return `Maybe<&2, Value>`. Use `value.text(value, fallback)`, `value.enabled(value)`, or `value.many(value)` to extract them. Keys use camel case: `--dry-run` becomes `dryRun`.
- **Command paths.** `path(input)` returns canonical names, including the root. Aliases resolve to their command names. Parent options remain available in children, and flags and keys must be unique along that path.
- **Parsing.** `parse(cmd, argv)` takes application tokens only. Repeated scalar options keep the last value; empty attached values such as `--port=` are preserved. Required-value options consume the next token even when it starts with `-`.
- **IO.** `run(cmd, handler)` combines `IO.args`, parsing, and dispatch. `dispatch(outcome, handler)` prints help or version, exits with status 1 on errors, or calls the handler. `Error{code, message}` lets applications choose another policy.
- **Help.** `help(cmd)` renders root help. `help child` and `child --help` render child help. Help and version stop parsing when encountered; earlier errors win and later tokens are ignored.

## Development

```sh
make setup
make check
make package
```

`make setup` installs the pinned compiler under `.tools/` after verifying its checksum. The installer supports Linux and macOS on x64 and arm64; native builds require Clang. Set `BEND=/absolute/path/to/bend` to use another compiler.

`make check` checks the library and [proofs](src/PROOF.bend). `make package` builds a source archive under `.build/` and checks it outside the checkout. This bootstrap repository contains no tests or testing dependencies. Read [AGENTS.md](AGENTS.md) for guidance on building CLIs with Zhao.

### Releases

The publishable package lives in `src/`, including [LAWS.bend](src/LAWS.bend) and [PROOF.bend](src/PROOF.bend). [Bendhub](https://hub.bend-lang.com) identifies packages by content hash; GitHub releases associate those hashes with Zhao versions.

Pushing a tag named `v` plus `VERSION` runs CI, publishes to Bendhub, and creates a GitHub release with the source archive and a `BENDHUB_IMPORT` file. CI checks the library, proofs, and packaging before publishing. Bendhub needs no account or token. `make publish` performs a manual upload, verifies the downloaded package, and writes the import statement to `.build/BENDHUB_IMPORT`.

## Status and limits

Zhao implements a subset of Commander conventions, informed by [Commander 15.0.0](https://github.com/tj/commander.js/tree/ba6d13ddb4243e5913367734f8c159089ffe7834). A command accepts positional arguments or groups subcommands; it cannot combine both. Short-only options, variadic options, combined positive/negative declarations for one key, environment options, choices, custom value parsers, conflicts, hooks, executable subcommands, suggestions, and configurable help layouts are not implemented.

The proofs cover the stated laws, not full parser correctness. Token scanning preserves input order; independent validation and help computations use Bend parallel calls. Native Bend can schedule those calls across CPU threads; the JavaScript backend runs them sequentially.

## License

[MIT](LICENSE). Copyright 2026 Lucas Coutinho.
