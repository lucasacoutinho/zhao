import Base
import ./zhao.bend as Zhao

law empty_command_parses:
  {Zhao.parse(Zhao.command("tool"), []) == Zhao.Parsed{Zhao.Invocation{["tool"], [], []}} : Zhao.Outcome}

law lookup_preserves_value:
  for +value: Zhao.Value
  {Zhao.get(Zhao.Invocation{[], [Zhao.Binding{"key", value}], []}, "key") == Some{value} : Maybe<&2, Zhao.Value>}

law absent_option_is_none:
  for key: String
  {Zhao.get(Zhao.Invocation{[], [], []}, key) == None{} : Maybe<&2, Zhao.Value>}

law option_and_argument_names_are_separate:
  for value: Zhao.Value
  {Zhao.get(Zhao.Invocation{[], [], [Zhao.Binding{"name", value}]}, "name") == None{} : Maybe<&2, Zhao.Value>}

law required_option_preserves_text:
  for +text: String
  {Zhao.parse(Zhao.option(Zhao.command("tool"), "--label <value>", ""), ["--label", text]) == Zhao.Parsed{Zhao.Invocation{["tool"], [Zhao.Binding{"label", Zhao.Text{text}}], []}} : Zhao.Outcome}

law repeated_value_uses_last:
  for +text: String
  {Zhao.parse(Zhao.option(Zhao.command("tool"), "--label <value>", ""), ["--label=first", "--label", text]) == Zhao.Parsed{Zhao.Invocation{["tool"], [Zhao.Binding{"label", Zhao.Text{text}}], []}} : Zhao.Outcome}

law negated_option_defaults_true:
  {Zhao.parse(Zhao.option(Zhao.command("tool"), "--no-color", ""), []) == Zhao.Parsed{Zhao.Invocation{["tool"], [Zhao.Binding{"color", Zhao.Boolean{True{}}}], []}} : Zhao.Outcome}

law negated_option_sets_false:
  {Zhao.parse(Zhao.option(Zhao.command("tool"), "--no-color", ""), ["--no-color"]) == Zhao.Parsed{Zhao.Invocation{["tool"], [Zhao.Binding{"color", Zhao.Boolean{False{}}}], []}} : Zhao.Outcome}

law delimiter_makes_help_literal:
  {Zhao.parse(Zhao.argument(Zhao.command("tool"), "<name>", ""), ["--", "--help"]) == Zhao.Parsed{Zhao.Invocation{["tool"], [], [Zhao.Binding{"name", Zhao.Text{"--help"}}]}} : Zhao.Outcome}

law missing_value_is_error:
  {Zhao.parse(Zhao.option(Zhao.command("tool"), "--label <value>", ""), ["--label"]) == Zhao.Error{"zhao.optionMissingArgument", "option '--label' argument missing"} : Zhao.Outcome}

law unknown_option_is_error:
  {Zhao.parse(Zhao.command("tool"), ["--unknown"]) == Zhao.Error{"zhao.unknownOption", "unknown option '--unknown'"} : Zhao.Outcome}
