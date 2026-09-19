import Base
import ../src/zhao.bend as Z

def command() -> Z.Command:
  root = Z.command("forge")
  root = Z.option_default(
    root,
    "-o, --output <path>",
    "output directory",
    "dist"
  )
  pack = Z.command("pack")
  pack = Z.alias(pack, "p")
  pack = Z.option_default(pack, "--format <name>", "archive format", "zip")
  pack = Z.argument(pack, "<input...>", "files to include")
  cache = Z.subcommand(Z.command("cache"), Z.command("clear"))
  root = Z.subcommand(root, pack)
  Z.subcommand(root, cache)

def summary.pack(+invocation: Z.Invocation, path: String) -> String:
  output = Z.value.text(Z.get(invocation, "output"), "dist")
  format = Z.value.text(Z.get(invocation, "format"), "zip")
  inputs = String.join(Z.value.many(Z.arg(invocation, "input")), ", ")
  path ++ ": " ++ inputs ++ " -> " ++ output ++ " (" ++ format ++ ")"

def summary.route(+invocation: Z.Invocation, path: String, clear: Bool) -> String:
  match clear:
    case True{}:
      path ++ ": cache cleared"
    case False{}:
      summary.pack(invocation, path)

def summary(+invocation: Z.Invocation) -> String:
  +path = String.join(Z.path(invocation), " ")
  summary.route(invocation, path, String.eq(path, "forge cache clear"))

def forge(invocation: Z.Invocation) -> IO(Unit):
  IO.print(summary(invocation))

def main() -> IO(Unit):
  Z.run(command(), forge)
