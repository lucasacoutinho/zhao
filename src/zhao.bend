# MIT License
#
# Copyright (c) 2026 Lucas Coutinho
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import Base
import ./text.bend as Text

type Value is Data:
  Boolean{value: Bool}
  Text{value: String}
  Many{values: List<&2, String>}

type Binding is Data:
  Binding{key: String, value: Value}

type OptionKind is Data:
  Flag{}
  Negated{}
  RequiredValue{name: String}
  OptionalValue{name: String}
  RepeatedValue{name: String}

type Option is Data:
  Option{flags: String, short: String, long: String, key: String, description: String, kind: OptionKind, fallback: Maybe<&2, Value>, mandatory: Bool}

type Argument is Data:
  Argument{syntax: String, key: String, description: String, required: Bool, variadic: Bool, fallback: Maybe<&2, String>}

type Command is Data:
  Command{name: String, description: String, version: String, alias: String, options: List<&2, Option>, arguments: List<&2, Argument>, commands: List<&2, Command>, problem: Maybe<&2, String>}

type Invocation is Data:
  Invocation{names: List<&2, String>, options: List<&2, Binding>, arguments: List<&2, Binding>}

type Outcome is Data:
  Parsed{invocation: Invocation}
  Help{text: String}
  Version{text: String}
  Error{code: String, message: String}

type OptionNames is Data:
  OptionNames{short: String, long: String, value: String}

type ArgumentState is Data:
  ArgumentState{words: List<&2, String>, values: List<&2, Binding>}

type Scan is Data:
  Active{command: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, literal: Bool, remaining: List<&2, String>}
  HelpRoute{command: Command, names: List<&2, String>, options: List<&2, Option>, remaining: List<&2, String>}
  Finished{outcome: Outcome}

def command.valid(name: String, valid: Bool) -> Command:
  match valid:
    case True{}:
      Command{name, "", "", "", [], [], [], None{}}
    case False{}:
      Command{name, "", "", "", [], [], [], Some{"command names must be nonempty identifiers"}}

def command(+name: String) -> Command:
  command.valid(name, Text.identifier(name) && Bool.not(String.starts_with(name, "-")))

def description(cmd: Command, text: String) -> Command:
  Command{n, _, v, a, os, args, cs, e} = cmd
  Command{n, text, v, a, os, args, cs, e}

def version(cmd: Command, text: String) -> Command:
  Command{n, d, _, a, os, args, cs, e} = cmd
  Command{n, d, text, a, os, args, cs, e}

def alias(cmd: Command, text: String) -> Command:
  Command{n, d, v, _, os, args, cs, e} = cmd
  Command{n, d, v, text, os, args, cs, e}

def problem.first(first: Maybe<&2, String>, second: Maybe<&2, String>) -> Maybe<&2, String>:
  match first:
    case Some{text}:
      Some{text}
    case None{}:
      second

def command.problem(cmd: Command, message: String) -> Command:
  Command{n, d, v, a, os, args, cs, e} = cmd
  Command{n, d, v, a, os, args, cs, problem.first(e, Some{message})}

def option.names.two(first: String, second: String, flag: Bool) -> Result<&2, &2, String, OptionNames>:
  match flag:
    case True{}:
      Done{OptionNames{first, second, ""}}
    case False{}:
      Done{OptionNames{"", first, second}}

def option.names(parts: List<&2, String>) -> Result<&2, &2, String, OptionNames>:
  match parts:
    case one <> Nil{}:
      Done{OptionNames{"", one, ""}}
    case one <> +two <> Nil{}:
      option.names.two(one, two, String.starts_with(two, "-"))
    case short <> long <> value <> Nil{}:
      Done{OptionNames{short, long, value}}
    case _:
      Fail{"expected '-s, --long', '--long <value>', or '--long [value]'"}

def option.short_valid(text: String) -> Bool:
  match text:
    case SNil{}:
      True{}
    case SCon{'-', SCon{c, SNil{}}}:
      Char.is_alpha(c)
    case _:
      False{}

def option.long_valid(+text: String) -> Bool:
  String.starts_with(text, "--") && Text.identifier(String.drop(text, 2n))

def option.kind.negated(empty: Bool) -> Result<&2, &2, String, OptionKind>:
  match empty:
    case True{}:
      Done{Negated{}}
    case False{}:
      Fail{"negated options cannot take a value"}

def option.kind.brackets(name: String, required: Bool, optional: Bool) -> Result<&2, &2, String, OptionKind>:
  match required optional:
    case True{} _:
      Done{RequiredValue{name}}
    case False{} True{}:
      Done{OptionalValue{name}}
    case False{} False{}:
      Fail{"option values need <required> or [optional] brackets"}

def option.kind.wrapped(+value: String, valid: Bool) -> Result<&2, &2, String, OptionKind>:
  match valid:
    case False{}:
      Fail{"invalid option value name"}
    case True{}:
      option.kind.brackets(Text.unwrap(value), String.starts_with(value, "<") && String.ends_with(value, ">"), String.starts_with(value, "[") && String.ends_with(value, "]"))

def option.kind.value(+value: String, empty: Bool) -> Result<&2, &2, String, OptionKind>:
  match empty:
    case True{}:
      Done{Flag{}}
    case False{}:
      option.kind.wrapped(value, Text.identifier(Text.unwrap(value)))

def option.kind(+value: String, negative: Bool) -> Result<&2, &2, String, OptionKind>:
  match negative:
    case True{}:
      option.kind.negated(String.is_empty(value))
    case False{}:
      option.kind.value(value, String.is_empty(value))

def option.key.prefix(negative: Bool) -> Nat:
  match negative:
    case True{}:
      5n
    case False{}:
      2n

def option.key(+long: String) -> String:
  Text.camel(String.drop(long, option.key.prefix(String.starts_with(long, "--no-"))))

def option.make.valid(flags: String, short: String, +long: String, desc: String, kind: OptionKind, fallback: Maybe<&2, Value>, mandatory: Bool, valid: Bool) -> Result<&2, &2, String, Option>:
  match valid:
    case False{}:
      Fail{"options need a --long-name and an optional one-letter short flag"}
    case True{}:
      Done{Option{flags, short, long, option.key(long), desc, kind, fallback, mandatory}}

def option.make.names(names: OptionNames, flags: String, desc: String, fallback: Maybe<&2, Value>, mandatory: Bool) -> Result<&2, &2, String, Option>:
  OptionNames{+short, +long, value} = names
  Result.bind(&2, &2, String, OptionKind, Option, option.kind(value, String.starts_with(long, "--no-")), kind => option.make.valid(flags, short, long, desc, kind, fallback, mandatory, option.short_valid(short) && option.long_valid(long) && Text.identifier(option.key(long))))

def option.make(+flags: String, desc: String, fallback: Maybe<&2, Value>, mandatory: Bool) -> Result<&2, &2, String, Option>:
  Result.bind(&2, &2, String, OptionNames, Option, option.names(Text.words(flags)), names => option.make.names(names, flags, desc, fallback, mandatory))

def option.clashes(+left: Option, +right: Option) -> Bool:
  Option{_, +s1, l1, k1, _, _, _, _} = left
  Option{_, s2, l2, k2, _, _, _, _} = right
  String.eq(l1, l2) || String.eq(k1, k2) || (Bool.not(String.is_empty(s1)) && String.eq(s1, s2))

def option.conflicts(options: List<&2, Option>, +added: Option) -> Bool:
  match options:
    case Nil{}:
      False{}
    case head <> tail:
      option.clashes(head, added) || option.conflicts(tail, added)

def option.reserved(opt: Option) -> Bool:
  Option{_, +short, +long, _, _, _, _, _} = opt
  String.eq(short, "-h") || String.eq(short, "-V") || String.eq(long, "--help") || String.eq(long, "--version")

def option.add.valid(cmd: Command, opt: Option, valid: Bool) -> Command:
  match cmd valid:
    case original False{}:
      command.problem(original, "duplicate or reserved option")
    case Command{n, d, v, a, os, args, cs, e} True{}:
      Command{n, d, v, a, List.append(&2, Option, os, [opt]), args, cs, e}

def option.add(cmd: Command, result: Result<&2, &2, String, Option>) -> Command:
  match cmd result:
    case +original Fail{message}:
      command.problem(original, message)
    case Command{n, d, v, a, +os, args, cs, e} Done{+opt}:
      option.add.valid(Command{n, d, v, a, os, args, cs, e}, opt, Bool.not(option.conflicts(os, opt) || option.reserved(opt)))

def option(cmd: Command, flags: String, desc: String) -> Command:
  option.add(cmd, option.make(flags, desc, None{}, False{}))

def option.default.valid(result: Result<&2, &2, String, Option>) -> Result<&2, &2, String, Option>:
  match result:
    case Done{Option{_, _, _, _, _, Flag{}, _, _}}:
      Fail{"string defaults require a value-taking option"}
    case Done{Option{_, _, _, _, _, Negated{}, _, _}}:
      Fail{"string defaults require a value-taking option"}
    case other:
      other

def option_default(cmd: Command, flags: String, desc: String, value: String) -> Command:
  option.add(cmd, option.default.valid(option.make(flags, desc, Some{Text{value}}, False{})))

def required_option(cmd: Command, flags: String, desc: String) -> Command:
  option.add(cmd, option.make(flags, desc, None{}, True{}))

def option.repeatable(result: Result<&2, &2, String, Option>) -> Result<&2, &2, String, Option>:
  match result:
    case Fail{message}:
      Fail{message}
    case Done{Option{flags, short, long, key, desc, RequiredValue{name}, fallback, mandatory}}:
      Done{Option{flags, short, long, key, desc, RepeatedValue{name}, fallback, mandatory}}
    case Done{_}:
      Fail{"repeatable options require <value> syntax"}

def repeatable_option(cmd: Command, flags: String, desc: String) -> Command:
  option.add(cmd, option.repeatable(option.make(flags, desc, None{}, False{})))

def argument.make.valid(syntax: String, name: String, desc: String, required: Bool, variadic: Bool, fallback: Maybe<&2, String>, valid: Bool) -> Result<&2, &2, String, Argument>:
  match valid:
    case False{}:
      Fail{"arguments need <required>, [optional], <many...>, or [many...] syntax"}
    case True{}:
      Done{Argument{syntax, name, desc, required, variadic, fallback}}

def argument.make(+syntax: String, desc: String, fallback: Maybe<&2, String>) -> Result<&2, &2, String, Argument>:
  +inner = Text.unwrap(syntax)
  +variadic = String.ends_with(inner, "...")
  +name = Text.choose(variadic, String.take(inner, Nat.sub(String.length(inner), 3n)), inner)
  +required = String.starts_with(syntax, "<") && String.ends_with(syntax, ">")
  valid = Text.identifier(name) && (required || (String.starts_with(syntax, "[") && String.ends_with(syntax, "]")))
  argument.make.valid(syntax, name, desc, required, variadic, fallback, valid)

def argument.conflicts(args: List<&2, Argument>, +added: Argument) -> Bool:
  match args:
    case Nil{}:
      False{}
    case Argument{_, key, _, required, variadic, _} <> rest:
      Argument{_, other, _, other_required, _, _} = added
      String.eq(key, other) || variadic || (Bool.not(required) && other_required) || argument.conflicts(rest, added)

def argument.add.valid(cmd: Command, spec: Argument, valid: Bool) -> Command:
  match cmd valid:
    case original False{}:
      command.problem(original, "arguments require unique names, required before optional, variadic last, and no subcommands")
    case Command{n, d, v, a, os, args, cs, e} True{}:
      Command{n, d, v, a, os, List.append(&2, Argument, args, [spec]), cs, e}

def argument.add(cmd: Command, result: Result<&2, &2, String, Argument>) -> Command:
  match cmd result:
    case +original Fail{message}:
      command.problem(original, message)
    case Command{n, d, v, a, os, +args, +cs, e} Done{+spec}:
      argument.add.valid(Command{n, d, v, a, os, args, cs, e}, spec, List.is_empty(&2, Command, cs) && Bool.not(argument.conflicts(args, spec)))

def argument(cmd: Command, syntax: String, desc: String) -> Command:
  argument.add(cmd, argument.make(syntax, desc, None{}))

def argument_default(cmd: Command, syntax: String, desc: String, value: String) -> Command:
  argument.add(cmd, argument.make(syntax, desc, Some{value}))

def command.matches(cmd: Command, +token: String) -> Bool:
  Command{name, _, _, +alt, _, _, _, _} = cmd
  String.eq(name, token) || (Bool.not(String.is_empty(alt)) && String.eq(alt, token))

def command.find.hit(hit: Bool, cmd: Command, rest: Maybe<&2, Command>) -> Maybe<&2, Command>:
  match hit:
    case True{}:
      Some{cmd}
    case False{}:
      rest

def command.find(commands: List<&2, Command>, +token: String) -> Maybe<&2, Command>:
  match commands:
    case Nil{}:
      None{}
    case +cmd <> rest:
      command.find.hit(command.matches(cmd, token), cmd, command.find(rest, token))

def command.conflicts(commands: List<&2, Command>, +name: String, +alt: String) -> Bool:
  match commands:
    case Nil{}:
      False{}
    case +cmd <> rest:
      command.matches(cmd, name) || (Bool.not(String.is_empty(alt)) && command.matches(cmd, alt)) || command.conflicts(rest, name, alt)

def subcommand.valid(cmd: Command, child: Command, valid: Bool) -> Command:
  match cmd valid:
    case original False{}:
      command.problem(original, "subcommands require unique names/aliases, cannot use help, and cannot share a command with positional arguments")
    case Command{n, d, v, a, os, args, cs, e} True{}:
      Command{n, d, v, a, os, args, List.append(&2, Command, cs, [child]), e}

def subcommand(cmd: Command, +child: Command) -> Command:
  Command{n, d, v, a, os, +args, +cs, e} = cmd
  Command{+cn, _, _, +ca, _, _, _, ce} = child
  valid = List.is_empty(&2, Argument, args) && Text.identifier(cn) && Bool.not(String.eq(cn, "help")) && (String.is_empty(ca) || (Text.identifier(ca) && Bool.not(String.starts_with(ca, "-")) && Bool.not(String.eq(ca, "help")))) && Bool.not(command.conflicts(cs, cn, ca))
  subcommand.valid(Command{n, d, v, a, os, args, cs, problem.first(e, ce)}, child, valid)

def bindings.get.hit(hit: Bool, value: Value, rest: Maybe<&2, Value>) -> Maybe<&2, Value>:
  match hit:
    case True{}:
      Some{value}
    case False{}:
      rest

def bindings.get(bindings: List<&2, Binding>, +key: String) -> Maybe<&2, Value>:
  match bindings:
    case Nil{}:
      None{}
    case Binding{name, value} <> rest:
      bindings.get.hit(String.eq(name, key), value, bindings.get(rest, key))

def get(invocation: Invocation, key: String) -> Maybe<&2, Value>:
  Invocation{_, options, _} = invocation
  bindings.get(options, key)

def arg(invocation: Invocation, key: String) -> Maybe<&2, Value>:
  Invocation{_, _, args} = invocation
  bindings.get(args, key)

def value.text(value: Maybe<&2, Value>, fallback: String) -> String:
  match value:
    case Some{Text{text}}:
      text
    case _:
      fallback

def value.enabled(value: Maybe<&2, Value>) -> Bool:
  match value:
    case Some{Boolean{enabled}}:
      enabled
    case _:
      False{}

def value.many(value: Maybe<&2, Value>) -> List<&2, String>:
  match value:
    case Some{Many{values}}:
      values
    case _:
      []

def path(invocation: Invocation) -> List<&2, String>:
  Invocation{names, _, _} = invocation
  names

def value.show(value: Value) -> String:
  match value:
    case Boolean{b}:
      Text.choose(b, "true", "false")
    case Text{s}:
      s
    case Many{ss}:
      String.join(ss, ", ")

def help.default(value: Maybe<&2, Value>) -> String:
  match value:
    case None{}:
      ""
    case Some{v}:
      " (default: " ++ value.show(v) ++ ")"

def help.options(options: List<&2, Option>) -> String:
  match options:
    case Nil{}:
      ""
    case Option{flags, _, _, _, desc, _, fallback, required} <> rest:
      "  " ++ flags ++ "  " ++ desc ++ help.default(fallback) ++ Text.choose(required, " (required)", "") ++ "\n" ++ help.options(rest)

def help.argument_default(value: Maybe<&2, String>) -> String:
  match value:
    case None{}:
      ""
    case Some{v}:
      " (default: " ++ v ++ ")"

def help.arguments(args: List<&2, Argument>) -> String:
  match args:
    case Nil{}:
      ""
    case Argument{syntax, _, desc, _, _, fallback} <> rest:
      "  " ++ syntax ++ "  " ++ desc ++ help.argument_default(fallback) ++ "\n" ++ help.arguments(rest)

def help.usage(args: List<&2, Argument>) -> String:
  match args:
    case Nil{}:
      ""
    case Argument{syntax, _, _, _, _, _} <> rest:
      " " ++ syntax ++ help.usage(rest)

def help.commands(commands: List<&2, Command>) -> String:
  match commands:
    case Nil{}:
      ""
    case Command{name, desc, _, +alt, _, args, _, _} <> rest:
      "  " ++ name ++ Text.choose(String.is_empty(alt), "", " (" ++ alt ++ ")") ++ help.usage(args) ++ "  " ++ desc ++ "\n" ++ help.commands(rest)

def help.section(title: String, +body: String) -> String:
  Text.choose(String.is_empty(body), "", "\n" ++ title ++ ":\n" ++ body)

def help.render(cmd: Command, names: List<&2, String>, options: List<&2, Option>) -> String:
  Command{_, +desc, +ver, _, _, +args, +commands, _} = cmd
  option_text argument_text = help.options(options) help.arguments(args)
  usage = "Usage: " ++ String.join(names, " ") ++ " [options]" ++ help.usage(args)
  child_usage = Text.choose(List.is_empty(&2, Command, commands), "", " <command>")
  intro = Text.choose(String.is_empty(desc), "", "\n" ++ desc ++ "\n")
  version_line = Text.choose(String.is_empty(ver), "", "  -V, --version  output the version number\n")
  command_text = Text.choose(List.is_empty(&2, Command, commands), "", help.commands(commands) ++ "  help [command...]  display help for command\n")
  usage ++ child_usage ++ "\n" ++ intro ++ help.section("Arguments", argument_text) ++ "\nOptions:\n" ++ option_text ++ "  -h, --help  display help for command\n" ++ version_line ++ help.section("Commands", command_text)

def help(+cmd: Command) -> String:
  Command{name, _, _, _, options, _, _, _} = cmd
  help.render(cmd, [name], options)

def bindings.remove.keep(remove: Bool, binding: Binding, rest: List<&2, Binding>) -> List<&2, Binding>:
  match remove:
    case True{}:
      rest
    case False{}:
      binding <> rest

def bindings.remove(bindings: List<&2, Binding>, +key: String) -> List<&2, Binding>:
  match bindings:
    case Nil{}:
      []
    case +binding <> rest:
      Binding{name, _} = binding
      bindings.remove.keep(String.eq(name, key), binding, bindings.remove(rest, key))

def bindings.set(bindings: List<&2, Binding>, +key: String, value: Value) -> List<&2, Binding>:
  Binding{key, value} <> bindings.remove(bindings, key)

def option.find.hit(hit: Bool, opt: Option, rest: Maybe<&2, Option>) -> Maybe<&2, Option>:
  match hit:
    case True{}:
      Some{opt}
    case False{}:
      rest

def option.find(options: List<&2, Option>, +flag: String) -> Maybe<&2, Option>:
  match options:
    case Nil{}:
      None{}
    case +opt <> rest:
      Option{_, short, long, _, _, _, _, _} = opt
      option.find.hit(String.eq(short, flag) || String.eq(long, flag), opt, option.find(rest, flag))

def options.clash(added: List<&2, Option>, +existing: List<&2, Option>) -> Bool:
  match added:
    case Nil{}:
      False{}
    case opt <> rest:
      option.conflicts(existing, opt) || options.clash(rest, existing)

def option.fallback(kind: OptionKind, fallback: Maybe<&2, Value>) -> Maybe<&2, Value>:
  match kind fallback:
    case _ Some{value}:
      Some{value}
    case Negated{} None{}:
      Some{Boolean{True{}}}
    case RepeatedValue{_} None{}:
      Some{Many{[]}}
    case _ None{}:
      None{}

def options.finish.value(values: List<&2, Binding>, key: String, current: Maybe<&2, Value>, fallback: Maybe<&2, Value>, mandatory: Bool, flags: String) -> Result<&2, &2, Outcome, List<&2, Binding>>:
  match current fallback mandatory:
    case Some{_} _ _:
      Done{values}
    case None{} Some{value} _:
      Done{bindings.set(values, key, value)}
    case None{} None{} True{}:
      Fail{Error{"zhao.missingMandatoryOptionValue", "required option '" ++ flags ++ "' not specified"}}
    case None{} None{} False{}:
      Done{values}

def options.finish(options: List<&2, Option>, result: Result<&2, &2, Outcome, List<&2, Binding>>) -> Result<&2, &2, Outcome, List<&2, Binding>>:
  match options result:
    case _ Fail{error}:
      Fail{error}
    case Nil{} Done{values}:
      Done{values}
    case Option{flags, _, _, +key, _, kind, fallback, mandatory} <> rest Done{+values}:
      options.finish(rest, options.finish.value(values, key, bindings.get(values, key), option.fallback(kind, fallback), mandatory, flags))

def argument.empty(values: List<&2, Binding>, key: String, required: Bool, variadic: Bool, fallback: Maybe<&2, String>) -> Result<&2, &2, Outcome, ArgumentState>:
  match required variadic fallback:
    case True{} _ _:
      Fail{Error{"zhao.missingArgument", "missing required argument '" ++ key ++ "'"}}
    case False{} False{} Some{value}:
      Done{ArgumentState{[], Binding{key, Text{value}} <> values}}
    case False{} True{} Some{value}:
      Done{ArgumentState{[], Binding{key, Many{[value]}} <> values}}
    case False{} True{} None{}:
      Done{ArgumentState{[], Binding{key, Many{[]}} <> values}}
    case False{} False{} None{}:
      Done{ArgumentState{[], values}}

def argument.consume(spec: Argument, words: List<&2, String>, values: List<&2, Binding>) -> Result<&2, &2, Outcome, ArgumentState>:
  match spec words:
    case Argument{_, key, _, required, variadic, fallback} Nil{}:
      argument.empty(values, key, required, variadic, fallback)
    case Argument{_, key, _, _, True{}, _} remaining:
      Done{ArgumentState{[], Binding{key, Many{remaining}} <> values}}
    case Argument{_, key, _, _, False{}, _} word <> tail:
      Done{ArgumentState{tail, Binding{key, Text{word}} <> values}}

def arguments.loop(args: List<&2, Argument>, state: Result<&2, &2, Outcome, ArgumentState>) -> Result<&2, &2, Outcome, List<&2, Binding>>:
  match args state:
    case _ Fail{error}:
      Fail{error}
    case Nil{} Done{ArgumentState{Nil{}, values}}:
      Done{List.reverse(&2, Binding, values)}
    case Nil{} Done{ArgumentState{_, _}}:
      Fail{Error{"zhao.excessArguments", "too many arguments"}}
    case spec <> rest Done{ArgumentState{words, values}}:
      arguments.loop(rest, argument.consume(spec, words, values))

def arguments.finish(args: List<&2, Argument>, words: List<&2, String>) -> Result<&2, &2, Outcome, List<&2, Binding>>:
  arguments.loop(args, Done{ArgumentState{words, []}})

def parse.complete.results(options: Result<&2, &2, Outcome, List<&2, Binding>>, args: Result<&2, &2, Outcome, List<&2, Binding>>, names: List<&2, String>) -> Outcome:
  match options args:
    case Fail{error} _:
      error
    case Done{_} Fail{error}:
      error
    case Done{values} Done{arguments}:
      Parsed{Invocation{names, values, arguments}}

def parse.complete.commands(commands: List<&2, Command>, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, args: List<&2, Argument>, words: List<&2, String>) -> Outcome:
  match commands:
    case Nil{}:
      parsed_options parsed_args = options.finish(options, Done{values}) arguments.finish(args, List.reverse(&2, String, words))
      parse.complete.results(parsed_options, parsed_args, names)
    case _ <> _:
      Error{"zhao.missingCommand", "missing command; use --help to list commands"}

def parse.complete(cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>) -> Outcome:
  Command{_, _, _, _, _, args, commands, _} = cmd
  parse.complete.commands(commands, names, options, values, args, words)

def parse.select.valid(cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, remaining: List<&2, String>, clash: Bool) -> Scan:
  match clash:
    case True{}:
      Finished{Error{"zhao.invalidDefinition", "subcommand options conflict with inherited options"}}
    case False{}:
      Active{cmd, names, options, values, [], False{}, remaining}

def parse.select(+child: Command, names: List<&2, String>, +options: List<&2, Option>, values: List<&2, Binding>, remaining: List<&2, String>) -> Scan:
  Command{name, _, _, _, +child_options, _, _, _} = child
  parse.select.valid(child, List.append(&2, String, names, [name]), List.append(&2, Option, options, child_options), values, remaining, options.clash(child_options, options))

def parse.word.child(found: Maybe<&2, Command>, children: List<&2, Command>, cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, word: String, remaining: List<&2, String>) -> Scan:
  match found children:
    case Some{child} _:
      parse.select(child, names, options, values, remaining)
    case None{} Nil{}:
      Active{cmd, names, options, values, word <> words, False{}, remaining}
    case None{} _:
      Finished{Error{"zhao.unknownCommand", "unknown command '" ++ word ++ "'"}}

def parse.word(+cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, +word: String, remaining: List<&2, String>) -> Scan:
  Command{_, _, _, _, _, _, +children, _} = cmd
  parse.word.child(command.find(children, word), children, cmd, names, options, values, words, word, remaining)

def option.store(kind: OptionKind, +values: List<&2, Binding>, +key: String, text: String) -> List<&2, Binding>:
  match kind:
    case RepeatedValue{_}:
      previous = value.many(bindings.get(values, key))
      bindings.set(values, key, Many{List.append(&2, String, previous, [text])})
    case _:
      bindings.set(values, key, Text{text})

def parse.required(remaining: List<&2, String>, cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, key: String, token: String, kind: OptionKind) -> Scan:
  match remaining:
    case Nil{}:
      Finished{Error{"zhao.optionMissingArgument", "option '" ++ token ++ "' argument missing"}}
    case text <> tail:
      Active{cmd, names, options, option.store(kind, values, key, text), words, False{}, tail}

def parse.optional.value(cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, key: String, text: String, tail: List<&2, String>, consume: Bool) -> Scan:
  match consume:
    case True{}:
      Active{cmd, names, options, bindings.set(values, key, Text{text}), words, False{}, tail}
    case False{}:
      Active{cmd, names, options, bindings.set(values, key, Boolean{True{}}), words, False{}, text <> tail}

def parse.optional(remaining: List<&2, String>, cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, key: String) -> Scan:
  match remaining:
    case Nil{}:
      Active{cmd, names, options, bindings.set(values, key, Boolean{True{}}), words, False{}, []}
    case +text <> tail:
      parse.optional.value(cmd, names, options, values, words, key, text, tail, Bool.not(Text.option_like(text)) || Text.negative_number(text))

def parse.builtin.kind(cmd: Command, names: List<&2, String>, options: List<&2, Option>, token: String, ver: String, is_help: Bool, is_version: Bool) -> Scan:
  match is_help is_version:
    case True{} _:
      Finished{Help{help.render(cmd, names, options)}}
    case False{} True{}:
      Finished{Version{ver}}
    case False{} False{}:
      Finished{Error{"zhao.unknownOption", "unknown option '" ++ token ++ "'"}}

def parse.builtin(+cmd: Command, names: List<&2, String>, options: List<&2, Option>, +token: String) -> Scan:
  Command{_, _, +ver, _, _, _, _, _} = cmd
  parse.builtin.kind(cmd, names, options, token, ver, String.eq(token, "--help") || String.eq(token, "-h"), (String.eq(token, "--version") || String.eq(token, "-V")) && Bool.not(String.is_empty(ver)))

def parse.option(found: Maybe<&2, Option>, attached: Maybe<&2, String>, cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, token: String, remaining: List<&2, String>) -> Scan:
  match found attached:
    case None{} _:
      parse.builtin(cmd, names, options, token)
    case Some{Option{_, _, _, key, _, Flag{}, _, _}} None{}:
      Active{cmd, names, options, bindings.set(values, key, Boolean{True{}}), words, False{}, remaining}
    case Some{Option{_, _, _, key, _, Negated{}, _, _}} None{}:
      Active{cmd, names, options, bindings.set(values, key, Boolean{False{}}), words, False{}, remaining}
    case Some{Option{_, _, _, _, _, Flag{}, _, _}} Some{_}:
      Finished{Error{"zhao.unknownOption", "unknown option '" ++ token ++ "'"}}
    case Some{Option{_, _, _, _, _, Negated{}, _, _}} Some{_}:
      Finished{Error{"zhao.unknownOption", "unknown option '" ++ token ++ "'"}}
    case Some{Option{_, _, _, key, _, kind, _, _}} Some{text}:
      Active{cmd, names, options, option.store(kind, values, key, text), words, False{}, remaining}
    case Some{Option{_, _, _, key, _, OptionalValue{_}, _, _}} None{}:
      parse.optional(remaining, cmd, names, options, values, words, key)
    case Some{Option{_, _, _, key, _, kind, _, _}} None{}:
      parse.required(remaining, cmd, names, options, values, words, key, token, kind)

def parse.flag.long(split: String & Maybe<&2, String>, cmd: Command, names: List<&2, String>, +options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, token: String, remaining: List<&2, String>) -> Scan:
  (+flag, attached) = split
  parse.option(option.find(options, flag), attached, cmd, names, options, values, words, token, remaining)

def parse.cluster(suffix: String, remaining: List<&2, String>) -> List<&2, String>:
  match suffix:
    case SNil{}:
      remaining
    case SCon{c, tail}:
      SCon{'-', SCon{c, tail}} <> remaining

def parse.attached(suffix: String) -> Maybe<&2, String>:
  match suffix:
    case SNil{}:
      None{}
    case SCon{c, tail}:
      Some{SCon{c, tail}}

def parse.flag.short.kind(kind: OptionKind, opt: Option, cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, flag: String, suffix: String, remaining: List<&2, String>) -> Scan:
  match kind:
    case Flag{}:
      parse.option(Some{opt}, None{}, cmd, names, options, values, words, flag, parse.cluster(suffix, remaining))
    case Negated{}:
      parse.option(Some{opt}, None{}, cmd, names, options, values, words, flag, parse.cluster(suffix, remaining))
    case _:
      parse.option(Some{opt}, parse.attached(suffix), cmd, names, options, values, words, flag, remaining)

def parse.flag.short(found: Maybe<&2, Option>, cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, flag: String, suffix: String, remaining: List<&2, String>) -> Scan:
  match found:
    case None{}:
      parse.builtin(cmd, names, options, flag)
    case Some{+opt}:
      Option{_, _, _, _, _, kind, _, _} = opt
      parse.flag.short.kind(kind, opt, cmd, names, options, values, words, flag, suffix, remaining)

def parse.flag.form(long: Bool, cmd: Command, names: List<&2, String>, +options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, +token: String, remaining: List<&2, String>) -> Scan:
  match long:
    case True{}:
      parse.flag.long(Text.split_equal(token), cmd, names, options, values, words, token, remaining)
    case False{}:
      +flag = String.take(token, 2n)
      suffix = String.drop(token, 2n)
      parse.flag.short(option.find(options, flag), cmd, names, options, values, words, flag, suffix, remaining)

def parse.flag(cmd: Command, names: List<&2, String>, +options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, +token: String, remaining: List<&2, String>) -> Scan:
  parse.flag.form(String.starts_with(token, "--"), cmd, names, options, values, words, token, remaining)

def parse.token.kind(cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, token: String, remaining: List<&2, String>, delimiter: Bool, flag: Bool, help_command: Bool) -> Scan:
  match delimiter flag help_command:
    case True{} _ _:
      Active{cmd, names, options, values, words, True{}, remaining}
    case False{} True{} _:
      parse.flag(cmd, names, options, values, words, token, remaining)
    case False{} False{} True{}:
      HelpRoute{cmd, names, options, remaining}
    case False{} False{} False{}:
      parse.word(cmd, names, options, values, words, token, remaining)

def parse.token(+cmd: Command, names: List<&2, String>, options: List<&2, Option>, values: List<&2, Binding>, words: List<&2, String>, +token: String, remaining: List<&2, String>) -> Scan:
  Command{_, _, _, _, _, _, +children, _} = cmd
  parse.token.kind(cmd, names, options, values, words, token, remaining, String.eq(token, "--"), Text.option_like(token) && Bool.not(List.is_empty(&2, Command, children) && Text.negative_number(token)), String.eq(token, "help") && Bool.not(List.is_empty(&2, Command, children)))

def parse.help.select(state: Scan) -> Scan:
  match state:
    case Active{cmd, names, options, _, _, _, remaining}:
      HelpRoute{cmd, names, options, remaining}
    case other:
      other

def parse.help.child(found: Maybe<&2, Command>, names: List<&2, String>, options: List<&2, Option>, token: String, remaining: List<&2, String>) -> Scan:
  match found:
    case None{}:
      Finished{Error{"zhao.unknownCommand", "unknown command '" ++ token ++ "'"}}
    case Some{child}:
      parse.help.select(parse.select(child, names, options, [], remaining))

def parse.step(state: Scan) -> Scan:
  match state:
    case Finished{outcome}:
      Finished{outcome}
    case Active{cmd, names, options, values, words, _, Nil{}}:
      Finished{parse.complete(cmd, names, options, values, words)}
    case Active{cmd, names, options, values, words, True{}, token <> tail}:
      Active{cmd, names, options, values, token <> words, True{}, tail}
    case Active{cmd, names, options, values, words, False{}, token <> tail}:
      parse.token(cmd, names, options, values, words, token, tail)
    case HelpRoute{cmd, names, options, Nil{}}:
      Finished{Help{help.render(cmd, names, options)}}
    case HelpRoute{Command{_, _, _, _, _, _, children, _}, names, options, +token <> tail}:
      parse.help.child(command.find(children, token), names, options, token, tail)

def parse.scan(fuel: Nat, state: Scan) -> Outcome:
  match fuel state:
    case _ Finished{outcome}:
      outcome
    case 0n _:
      Error{"zhao.internal", "parser exhausted its token bound"}
    case 1n+remaining active:
      parse.scan(remaining, parse.step(active))

def parse.start(+cmd: Command, +argv: List<&2, String>, problem: Maybe<&2, String>) -> Outcome:
  match cmd problem:
    case _ Some{message}:
      Error{"zhao.invalidDefinition", message}
    case Command{+name, +d, +v, +a, +options, +args, +children, +p} None{}:
      parse.scan(1n+Text.weight(argv), Active{Command{name, d, v, a, options, args, children, p}, [name], options, [], [], False{}, argv})

def parse(+cmd: Command, argv: List<&2, String>) -> Outcome:
  Command{_, _, _, _, _, _, _, problem} = cmd
  parse.start(cmd, argv, problem)

def dispatch(outcome: Outcome, action: Invocation -> IO(Unit)) -> IO(Unit):
  match outcome:
    case Parsed{invocation}:
      action(invocation)
    case Help{text}:
      IO.write(text)
    case Version{text}:
      IO.print(text)
    case Error{_, message}:
      IO.die(Unit, 1, "error: " ++ message)

def run(cmd: Command, action: Invocation -> IO(Unit)) -> IO(Unit):
  do IO<Unit>:
    argv : List<String> <- IO.args()
    dispatch(parse(cmd, Text.strings(argv)), action)
