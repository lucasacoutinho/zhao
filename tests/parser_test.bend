import Base
import ../../best/best.bend as Best
import ../src/zhao.bend as Z

def missing(value: Maybe<&2, Z.Value>) -> Bool:
  match value:
    case None{}:
      True{}
    case Some{_}:
      False{}

def error_code(outcome: Z.Outcome) -> String:
  match outcome:
    case Z.Error{code, _}:
      code
    case _:
      "<not an error>"

def error_is(+outcome: Z.Outcome, expected: String) -> Best.Check:
  Best.string.to_be(error_code(outcome), expected)

def bool_is(actual: Bool, expected: Bool) -> Bool:
  match actual expected:
    case True{} True{}:
      True{}
    case False{} False{}:
      True{}
    case _ _:
      False{}

def path_is(+outcome: Z.Outcome, expected: String) -> Best.Check:
  match outcome:
    case Z.Parsed{invocation}:
      Best.string.to_be(String.join(Z.path(invocation), "/"), expected)
    case _:
      Best.expect(False{}, "parsed path " ++ expected, "an error outcome")

def option_text(+outcome: Z.Outcome, key: String, expected: String) -> Best.Check:
  match outcome:
    case Z.Parsed{invocation}:
      Best.string.to_be(Z.value.text(Z.get(invocation, key), "<missing>"), expected)
    case _:
      Best.expect(False{}, "option " ++ key ++ " = " ++ expected, "an error outcome")

def option_missing(+outcome: Z.Outcome, key: String) -> Best.Check:
  match outcome:
    case Z.Parsed{invocation}:
      Best.bool.to_be_true(missing(Z.get(invocation, key)))
    case _:
      Best.expect(False{}, "option " ++ key ++ " is absent", "an error outcome")

def option_enabled(+outcome: Z.Outcome, key: String, expected: Bool) -> Best.Check:
  match outcome:
    case Z.Parsed{invocation}:
      Best.bool.to_be_true(bool_is(Z.value.enabled(Z.get(invocation, key)), expected))
    case _:
      Best.expect(False{}, "option " ++ key ++ " has the expected state", "an error outcome")

def argument_text(+outcome: Z.Outcome, key: String, expected: String) -> Best.Check:
  match outcome:
    case Z.Parsed{invocation}:
      Best.string.to_be(Z.value.text(Z.arg(invocation, key), "<missing>"), expected)
    case _:
      Best.expect(False{}, "argument " ++ key ++ " = " ++ expected, "an error outcome")

def argument_missing(+outcome: Z.Outcome, key: String) -> Best.Check:
  match outcome:
    case Z.Parsed{invocation}:
      Best.bool.to_be_true(missing(Z.arg(invocation, key)))
    case _:
      Best.expect(False{}, "argument " ++ key ++ " is absent", "an error outcome")

def argument_many(+outcome: Z.Outcome, key: String, expected: String) -> Best.Check:
  match outcome:
    case Z.Parsed{invocation}:
      Best.string.to_be(String.join(Z.value.many(Z.arg(invocation, key)), ","), expected)
    case _:
      Best.expect(False{}, "argument " ++ key ++ " has many values", "an error outcome")

def help_contains(+outcome: Z.Outcome, expected: String) -> Best.Check:
  match outcome:
    case Z.Help{text}:
      Best.string.to_contain(text, expected)
    case _:
      Best.expect(False{}, "help text containing " ++ expected, "a non-help outcome")

def version_is(outcome: Z.Outcome, expected: String) -> Best.Check:
  match outcome:
    case Z.Version{text}:
      Best.string.to_be(text, expected)
    case _:
      Best.expect(False{}, "version " ++ expected, "a non-version outcome")

def basic_parse() -> List<Best.Check>:
  cmd = Z.argument(
    Z.option(Z.command("app"), "-v, --verbose", "show verbose output"),
    "<name>",
    "the name"
  )
  +outcome = Z.parse(cmd, ["Ada"])
  [
    path_is(outcome, "app"),
    argument_text(outcome, "name", "Ada"),
    option_missing(outcome, "verbose")
  ]

def boolean_flag() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "-v, --verbose", "show verbose output")
  +outcome = Z.parse(cmd, ["--verbose"])
  [option_enabled(outcome, "verbose", True{})]

def boolean_short_alias() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "-v, --verbose", "show verbose output")
  +outcome = Z.parse(cmd, ["-v"])
  [option_enabled(outcome, "verbose", True{})]

def boolean_absent_is_none() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--verbose", "show verbose output")
  +outcome = Z.parse(cmd, [])
  [option_missing(outcome, "verbose")]

def negated_boolean() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--no-cache", "disable the cache")
  +outcome = Z.parse(cmd, ["--no-cache"])
  [option_enabled(outcome, "cache", False{})]

def negated_boolean_defaults_true() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--no-cache", "disable the cache")
  +outcome = Z.parse(cmd, [])
  [option_enabled(outcome, "cache", True{})]

def required_option_value() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "-p, --port <number>", "listen port")
  +outcome = Z.parse(cmd, ["--port", "8080"])
  [option_text(outcome, "port", "8080")]

def attached_short_value() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "-p, --port <number>", "listen port")
  +outcome = Z.parse(cmd, ["-p8080"])
  [option_text(outcome, "port", "8080")]

def equals_long_value() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--port <number>", "listen port")
  +outcome = Z.parse(cmd, ["--port=8080"])
  [option_text(outcome, "port", "8080")]

def optional_option_value() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--color [name]", "color name")
  +outcome = Z.parse(cmd, ["--color", "blue"])
  [option_text(outcome, "color", "blue")]

def default_option_value() -> List<Best.Check>:
  cmd = Z.option_default(Z.command("app"), "--format <name>", "output format", "json")
  +outcome = Z.parse(cmd, [])
  [option_text(outcome, "format", "json")]

def scalar_repeat_last_wins() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--port <number>", "listen port")
  +outcome = Z.parse(cmd, ["--port", "80", "--port", "443"])
  [option_text(outcome, "port", "443")]

def short_boolean_cluster() -> List<Best.Check>:
  cmd = Z.option(
    Z.option(
      Z.option(Z.command("app"), "-a, --all", "all files"),
      "-b, --batch",
      "batch mode"
    ),
    "-c, --color",
    "color output"
  )
  +outcome = Z.parse(cmd, ["-abc"])
  [
    option_enabled(outcome, "all", True{}),
    option_enabled(outcome, "batch", True{}),
    option_enabled(outcome, "color", True{})
  ]

def double_dash_stops_options() -> List<Best.Check>:
  cmd = Z.argument(
    Z.option(Z.command("app"), "--verbose", "show verbose output"),
    "<value>",
    "literal value"
  )
  +outcome = Z.parse(cmd, ["--", "--verbose"])
  [
    argument_text(outcome, "value", "--verbose"),
    option_missing(outcome, "verbose")
  ]

def mandatory_option_is_accepted() -> List<Best.Check>:
  cmd = Z.required_option(Z.command("app"), "--token <value>", "access token")
  +outcome = Z.parse(cmd, ["--token", "secret"])
  [option_text(outcome, "token", "secret")]

def missing_required_argument() -> List<Best.Check>:
  cmd = Z.argument(Z.command("app"), "<file>", "input file")
  [error_is(Z.parse(cmd, []), "zhao.missingArgument")]

def optional_argument_default() -> List<Best.Check>:
  cmd = Z.argument_default(Z.command("app"), "[format]", "output format", "json")
  +outcome = Z.parse(cmd, [])
  [argument_text(outcome, "format", "json")]

def optional_argument_override() -> List<Best.Check>:
  cmd = Z.argument_default(Z.command("app"), "[format]", "output format", "json")
  +outcome = Z.parse(cmd, ["yaml"])
  [argument_text(outcome, "format", "yaml")]

def variadic_arguments() -> List<Best.Check>:
  cmd = Z.argument(Z.command("app"), "<input...>", "input files")
  +outcome = Z.parse(cmd, ["one", "two", "three"])
  [argument_many(outcome, "input", "one,two,three")]

def missing_variadic_argument() -> List<Best.Check>:
  cmd = Z.argument(Z.command("app"), "<input...>", "input files")
  [error_is(Z.parse(cmd, []), "zhao.missingArgument")]

def excess_arguments() -> List<Best.Check>:
  cmd = Z.argument(Z.command("app"), "<file>", "input file")
  [error_is(Z.parse(cmd, ["one", "two"]), "zhao.excessArguments")]

def unknown_option() -> List<Best.Check>:
  [error_is(Z.parse(Z.command("app"), ["--unknown"]), "zhao.unknownOption")]

def missing_option_argument() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--port <number>", "listen port")
  [error_is(Z.parse(cmd, ["--port"]), "zhao.optionMissingArgument")]

def missing_mandatory_option() -> List<Best.Check>:
  cmd = Z.required_option(Z.command("app"), "--token <value>", "access token")
  [error_is(Z.parse(cmd, []), "zhao.missingMandatoryOptionValue")]

def unknown_command() -> List<Best.Check>:
  child = Z.command("serve")
  root = Z.subcommand(Z.command("app"), child)
  [error_is(Z.parse(root, ["deploy"]), "zhao.unknownCommand")]

def help_outcome() -> List<Best.Check>:
  cmd = Z.description(Z.command("app"), "an example application")
  [help_contains(Z.parse(cmd, ["--help"]), "app")]

def version_outcome() -> List<Best.Check>:
  cmd = Z.version(Z.command("app"), "1.2.3")
  [version_is(Z.parse(cmd, ["--version"]), "1.2.3")]

def kebab_option_key() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--dry-run", "do not write")
  +outcome = Z.parse(cmd, ["--dry-run"])
  [option_enabled(outcome, "dryRun", True{})]

def option_and_argument_can_coexist() -> List<Best.Check>:
  cmd = Z.argument(
    Z.option(Z.command("app"), "--force", "force the operation"),
    "<file>",
    "input file"
  )
  +outcome = Z.parse(cmd, ["--force", "README.md"])
  [
    option_enabled(outcome, "force", True{}),
    argument_text(outcome, "file", "README.md")
  ]

def parser_is_independent_between_runs() -> List<Best.Check>:
  +cmd = Z.option(Z.command("app"), "--port <number>", "listen port")
  +first = Z.parse(cmd, ["--port", "80"])
  +second = Z.parse(cmd, ["--port", "443"])
  [
    option_text(first, "port", "80"),
    option_text(second, "port", "443")
  ]

def nested_command_path() -> List<Best.Check>:
  child = Z.option(Z.command("serve"), "--port <number>", "listen port")
  root = Z.subcommand(Z.command("app"), child)
  +outcome = Z.parse(root, ["serve", "--port", "8080"])
  [
    path_is(outcome, "app/serve"),
    option_text(outcome, "port", "8080")
  ]

def nested_command_alias() -> List<Best.Check>:
  child = Z.alias(Z.command("serve"), "s")
  root = Z.subcommand(Z.command("app"), child)
  [path_is(Z.parse(root, ["s"]), "app/serve")]

def inherited_option_before_child() -> List<Best.Check>:
  child = Z.command("serve")
  root = Z.subcommand(
    Z.option(Z.command("app"), "--verbose", "show verbose output"),
    child
  )
  +outcome = Z.parse(root, ["--verbose", "serve"])
  [
    path_is(outcome, "app/serve"),
    option_enabled(outcome, "verbose", True{})
  ]

def inherited_option_after_child() -> List<Best.Check>:
  child = Z.command("serve")
  root = Z.subcommand(
    Z.option(Z.command("app"), "--verbose", "show verbose output"),
    child
  )
  +outcome = Z.parse(root, ["serve", "--verbose"])
  [
    path_is(outcome, "app/serve"),
    option_enabled(outcome, "verbose", True{})
  ]

def nested_alias_and_inherited_option() -> List<Best.Check>:
  child = Z.option(Z.alias(Z.command("serve"), "s"), "--port <number>", "listen port")
  root = Z.subcommand(
    Z.option(Z.command("app"), "--verbose", "show verbose output"),
    child
  )
  +outcome = Z.parse(root, ["--verbose", "s", "--port=80"])
  [
    path_is(outcome, "app/serve"),
    option_enabled(outcome, "verbose", True{}),
    option_text(outcome, "port", "80")
  ]

def nested_help() -> List<Best.Check>:
  child = Z.description(Z.command("serve"), "the server command")
  root = Z.subcommand(Z.command("app"), child)
  [help_contains(Z.parse(root, ["serve", "--help"]), "serve")]

def parent_child_flag_clash_is_invalid() -> List<Best.Check>:
  child = Z.option(Z.command("serve"), "--verbose", "child verbose")
  root = Z.subcommand(
    Z.option(Z.command("app"), "--verbose", "parent verbose"),
    child
  )
  [error_is(Z.parse(root, ["serve"]), "zhao.invalidDefinition")]

def parent_child_key_clash_is_invalid() -> List<Best.Check>:
  child = Z.option(Z.command("serve"), "--dryRun", "child dry run")
  root = Z.subcommand(
    Z.option(Z.command("app"), "--dry-run", "parent dry run"),
    child
  )
  [error_is(Z.parse(root, ["serve"]), "zhao.invalidDefinition")]

def required_before_optional_is_invalid() -> List<Best.Check>:
  cmd = Z.argument(
    Z.argument(Z.command("app"), "[maybe]", "optional value"),
    "<required>",
    "required value"
  )
  [error_is(Z.parse(cmd, []), "zhao.invalidDefinition")]

def variadic_must_be_last() -> List<Best.Check>:
  cmd = Z.argument(
    Z.argument(Z.command("app"), "<inputs...>", "input values"),
    "[tail]",
    "tail value"
  )
  [error_is(Z.parse(cmd, []), "zhao.invalidDefinition")]

def duplicate_option_is_invalid() -> List<Best.Check>:
  cmd = Z.option(
    Z.option(Z.command("app"), "--port <number>", "first port"),
    "--port <number>",
    "second port"
  )
  [error_is(Z.parse(cmd, []), "zhao.invalidDefinition")]

def reserved_option_is_invalid() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--help", "shadow help")
  [error_is(Z.parse(cmd, []), "zhao.invalidDefinition")]

def invalid_option_syntax_is_invalid() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "port", "missing long flag")
  [error_is(Z.parse(cmd, []), "zhao.invalidDefinition")]

def invalid_argument_syntax_is_invalid() -> List<Best.Check>:
  cmd = Z.argument(Z.command("app"), "name", "missing brackets")
  [error_is(Z.parse(cmd, []), "zhao.invalidDefinition")]

def duplicate_subcommand_is_invalid() -> List<Best.Check>:
  +child = Z.command("serve")
  root = Z.subcommand(Z.subcommand(Z.command("app"), child), child)
  [error_is(Z.parse(root, []), "zhao.invalidDefinition")]

def unknown_option_value_is_not_an_argument() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--port <number>", "listen port")
  [error_is(Z.parse(cmd, ["--unknown", "80"]), "zhao.unknownOption")]

def many_value_accessor() -> List<Best.Check>:
  cmd = Z.argument(Z.command("app"), "[files...]", "input files")
  +outcome = Z.parse(cmd, ["a", "b"])
  [argument_many(outcome, "files", "a,b")]

def unknown_option_lookup_is_none() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--verbose", "show verbose output")
  +outcome = Z.parse(cmd, [])
  [option_missing(outcome, "missing")]

def unknown_argument_lookup_is_none() -> List<Best.Check>:
  +outcome = Z.parse(Z.command("app"), [])
  [argument_missing(outcome, "missing")]

def empty_equals_value() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--name <value>", "a name")
  +outcome = Z.parse(cmd, ["--name="])
  [option_text(outcome, "name", "")]

def optional_value_without_token() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--color [name]", "color name")
  +outcome = Z.parse(cmd, ["--color"])
  [option_enabled(outcome, "color", True{})]

def optional_value_followed_by_flag() -> List<Best.Check>:
  cmd = Z.option(
    Z.option(Z.command("app"), "--color [name]", "color name"),
    "--verbose",
    "show verbose output"
  )
  +outcome = Z.parse(cmd, ["--color", "--verbose"])
  [
    option_enabled(outcome, "color", True{}),
    option_enabled(outcome, "verbose", True{})
  ]

def optional_negative_numbers() -> List<Best.Check>:
  +cmd = Z.option(Z.command("app"), "--threshold [value]", "threshold")
  +decimal = Z.parse(cmd, ["--threshold", "-1.5"])
  +exponent = Z.parse(cmd, ["--threshold", "-2.5e+4"])
  [
    option_text(decimal, "threshold", "-1.5"),
    option_text(exponent, "threshold", "-2.5e+4")
  ]

def malformed_negative_optional_value() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--threshold [value]", "threshold")
  [error_is(Z.parse(cmd, ["--threshold", "-not-a-number"]), "zhao.unknownOption")]

def required_option_consumes_help() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--name <value>", "a name")
  [option_text(Z.parse(cmd, ["--name", "--help"]), "name", "--help")]

def required_option_consumes_delimiter() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--name <value>", "a name")
  [option_text(Z.parse(cmd, ["--name", "--"]), "name", "--")]

def boolean_equals_is_rejected() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--verbose", "show verbose output")
  [error_is(Z.parse(cmd, ["--verbose=true"]), "zhao.unknownOption")]

def lone_dash_is_positional() -> List<Best.Check>:
  cmd = Z.argument(Z.command("app"), "<value>", "a value")
  [argument_text(Z.parse(cmd, ["-"]), "value", "-")]

def empty_optional_variadic() -> List<Best.Check>:
  cmd = Z.argument(Z.command("app"), "[files...]", "input files")
  [argument_many(Z.parse(cmd, []), "files", "")]

def missing_subcommand() -> List<Best.Check>:
  root = Z.subcommand(Z.command("app"), Z.command("serve"))
  [error_is(Z.parse(root, []), "zhao.missingCommand")]

def deep_help_inherits_options() -> List<Best.Check>:
  grandchild = Z.command("clear")
  middle = Z.subcommand(
    Z.option(Z.command("cache"), "--cache-dir <path>", "cache directory"),
    grandchild
  )
  root = Z.subcommand(
    Z.option(Z.command("app"), "--verbose", "show verbose output"),
    middle
  )
  +outcome = Z.parse(root, ["cache", "clear", "--help"])
  [
    help_contains(outcome, "Usage: app cache clear"),
    help_contains(outcome, "--verbose"),
    help_contains(outcome, "--cache-dir")
  ]

def help_stops_before_later_error() -> List<Best.Check>:
  +cmd = Z.option(Z.command("app"), "--verbose", "show verbose output")
  +early = Z.parse(cmd, ["--help", "--unknown"])
  +late = Z.parse(cmd, ["--unknown", "--help"])
  [
    help_contains(early, "Usage: app"),
    error_is(late, "zhao.unknownOption")
  ]

def version_stops_before_later_error() -> List<Best.Check>:
  +cmd = Z.version(Z.command("app"), "1.2.3")
  +early = Z.parse(cmd, ["--version", "--unknown"])
  +late = Z.parse(cmd, ["--unknown", "--version"])
  [
    version_is(early, "1.2.3"),
    error_is(late, "zhao.unknownOption")
  ]

def empty_command_is_invalid() -> List<Best.Check>:
  [error_is(Z.parse(Z.command(""), []), "zhao.invalidDefinition")]

def boolean_default_is_invalid() -> List<Best.Check>:
  cmd = Z.option_default(Z.command("app"), "--verbose", "show verbose output", "true")
  [error_is(Z.parse(cmd, []), "zhao.invalidDefinition")]

def arguments_before_subcommand_are_invalid() -> List<Best.Check>:
  root = Z.subcommand(
    Z.argument(Z.command("app"), "[file]", "input file"),
    Z.command("serve")
  )
  [error_is(Z.parse(root, []), "zhao.invalidDefinition")]

def arguments_after_subcommand_are_invalid() -> List<Best.Check>:
  root = Z.subcommand(Z.command("app"), Z.command("serve"))
  root = Z.argument(root, "[file]", "input file")
  [error_is(Z.parse(root, []), "zhao.invalidDefinition")]

def required_argument_default_still_requires_input() -> List<Best.Check>:
  cmd = Z.argument_default(Z.command("app"), "<file>", "input file", "fallback")
  [error_is(Z.parse(cmd, []), "zhao.missingArgument")]

def leading_dash_alias_is_invalid() -> List<Best.Check>:
  child = Z.alias(Z.command("serve"), "-s")
  root = Z.subcommand(Z.command("app"), child)
  [error_is(Z.parse(root, []), "zhao.invalidDefinition")]

def unicode_option_value() -> List<Best.Check>:
  cmd = Z.option(Z.command("app"), "--name <value>", "a name")
  [option_text(Z.parse(cmd, ["--name", "Olá λ"]), "name", "Olá λ")]

def negative_positional() -> List<Best.Check>:
  +cmd = Z.argument(Z.command("app"), "<number>", "number")
  [
    argument_text(Z.parse(cmd, ["-5"]), "number", "-5"),
    argument_text(Z.parse(cmd, ["-.1"]), "number", "-.1"),
    argument_text(Z.parse(cmd, ["-1e-3"]), "number", "-1e-3"),
    error_is(Z.parse(cmd, ["-1."]), "zhao.unknownOption")
  ]

def help_command_routes() -> List<Best.Check>:
  child = Z.subcommand(Z.command("cache"), Z.command("clear"))
  +root = Z.subcommand(Z.option(Z.command("app"), "--verbose", ""), child)
  +outcome = Z.parse(root, ["help", "cache", "clear"])
  [
    help_contains(outcome, "Usage: app cache clear"),
    help_contains(outcome, "--verbose"),
    error_is(Z.parse(root, ["help", "missing"]), "zhao.unknownCommand")
  ]

def help_command_rejects_conflicts() -> List<Best.Check>:
  root = Z.option(Z.command("app"), "--verbose", "")
  child = Z.option(Z.command("child"), "--verbose", "")
  [error_is(Z.parse(Z.subcommand(root, child), ["help", "child"]), "zhao.invalidDefinition")]

def suite() -> Best.Suite:
  Best.suite([
    Best.it("accepts negative numeric positional arguments", _ => negative_positional()),
    Best.it("routes the explicit help command", _ => help_command_routes()),
    Best.it("checks inherited conflicts on help routes", _ => help_command_rejects_conflicts()),
    Best.describe("basic parsing", [
      Best.it("parses a required argument and canonical path", _ => basic_parse()),
      Best.it("accepts a long boolean flag", _ => boolean_flag()),
      Best.it("accepts a short boolean alias", _ => boolean_short_alias()),
      Best.it("keeps an absent boolean as None", _ => boolean_absent_is_none()),
      Best.it("defaults a negated boolean to true", _ => negated_boolean_defaults_true()),
      Best.it("sets a negated boolean false", _ => negated_boolean()),
      Best.it("parses a required option value", _ => required_option_value()),
      Best.it("parses an attached short value", _ => attached_short_value()),
      Best.it("parses an equals long value", _ => equals_long_value()),
      Best.it("parses an optional option value", _ => optional_option_value()),
      Best.it("uses an option default", _ => default_option_value()),
      Best.it("uses the last repeated scalar value", _ => scalar_repeat_last_wins()),
      Best.it("parses short boolean clusters", _ => short_boolean_cluster()),
      Best.it("stops options after double dash", _ => double_dash_stops_options()),
      Best.it("accepts a mandatory option", _ => mandatory_option_is_accepted()),
      Best.it("uses an optional argument default", _ => optional_argument_default()),
      Best.it("overrides an optional argument default", _ => optional_argument_override()),
      Best.it("collects variadic arguments", _ => variadic_arguments()),
      Best.it("allows options and arguments together", _ => option_and_argument_can_coexist()),
      Best.it("maps kebab flags to camel keys", _ => kebab_option_key()),
      Best.it("keeps parser runs independent", _ => parser_is_independent_between_runs()),
      Best.it("reads an absent option as None", _ => unknown_option_lookup_is_none()),
      Best.it("reads an absent argument as None", _ => unknown_argument_lookup_is_none()),
      Best.it("exposes variadic values through value.many", _ => many_value_accessor()),
      Best.it("preserves an empty equals value", _ => empty_equals_value()),
      Best.it("treats an optional value without a token as true", _ => optional_value_without_token()),
      Best.it("keeps a known flag after an optional value", _ => optional_value_followed_by_flag()),
      Best.it("accepts negative decimal and exponent option values", _ => optional_negative_numbers()),
      Best.it("keeps malformed negatives as unknown options", _ => malformed_negative_optional_value()),
      Best.it("allows a required option to consume help", _ => required_option_consumes_help()),
      Best.it("allows a required option to consume the delimiter", _ => required_option_consumes_delimiter()),
      Best.it("treats a lone dash as positional", _ => lone_dash_is_positional()),
      Best.it("keeps an empty optional variadic list", _ => empty_optional_variadic()),
      Best.it("preserves Unicode option values", _ => unicode_option_value())
    ]),
    Best.describe("outcomes", [
      Best.it("reports a missing argument", _ => missing_required_argument()),
      Best.it("reports a missing variadic argument", _ => missing_variadic_argument()),
      Best.it("reports excess arguments", _ => excess_arguments()),
      Best.it("reports an unknown option", _ => unknown_option()),
      Best.it("reports a missing option argument", _ => missing_option_argument()),
      Best.it("reports a missing mandatory option", _ => missing_mandatory_option()),
      Best.it("reports an unknown command", _ => unknown_command()),
      Best.it("returns help text", _ => help_outcome()),
      Best.it("returns the configured version", _ => version_outcome()),
      Best.it("keeps an unknown value out of option lookup", _ => unknown_option_value_is_not_an_argument()),
      Best.it("rejects boolean equals syntax", _ => boolean_equals_is_rejected()),
      Best.it("reports a missing subcommand", _ => missing_subcommand()),
      Best.it("stops help before a later error", _ => help_stops_before_later_error()),
      Best.it("stops version before a later error", _ => version_stops_before_later_error())
    ]),
    Best.describe("nested commands", [
      Best.it("records a canonical nested path", _ => nested_command_path()),
      Best.it("resolves a nested command alias", _ => nested_command_alias()),
      Best.it("inherits options before a child", _ => inherited_option_before_child()),
      Best.it("inherits options after a child", _ => inherited_option_after_child()),
      Best.it("combines aliases and inherited options", _ => nested_alias_and_inherited_option()),
      Best.it("returns nested help text", _ => nested_help()),
      Best.it("routes three-level help with inherited options", _ => deep_help_inherits_options())
    ]),
    Best.describe("definition validation", [
      Best.it("rejects a parent and child flag clash", _ => parent_child_flag_clash_is_invalid()),
      Best.it("rejects a parent and child key clash", _ => parent_child_key_clash_is_invalid()),
      Best.it("rejects a required argument after an optional one", _ => required_before_optional_is_invalid()),
      Best.it("rejects an argument after a variadic one", _ => variadic_must_be_last()),
      Best.it("rejects duplicate options", _ => duplicate_option_is_invalid()),
      Best.it("rejects reserved options", _ => reserved_option_is_invalid()),
      Best.it("rejects invalid option syntax", _ => invalid_option_syntax_is_invalid()),
      Best.it("rejects invalid argument syntax", _ => invalid_argument_syntax_is_invalid()),
      Best.it("rejects duplicate subcommands", _ => duplicate_subcommand_is_invalid()),
      Best.it("rejects an empty command name", _ => empty_command_is_invalid()),
      Best.it("rejects a string default on a boolean", _ => boolean_default_is_invalid()),
      Best.it("rejects arguments before subcommands", _ => arguments_before_subcommand_are_invalid()),
      Best.it("rejects arguments after subcommands", _ => arguments_after_subcommand_are_invalid()),
      Best.it("keeps required arguments required despite defaults", _ => required_argument_default_still_requires_input()),
      Best.it("rejects aliases beginning with a dash", _ => leading_dash_alias_is_invalid())
    ])
  ])
