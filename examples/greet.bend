import Base
import ../src/zhao.bend as Z

def command() -> Z.Command:
  cmd = Z.command("greet")
  cmd = Z.description(cmd, "greet someone from the command line")
  cmd = Z.version(cmd, "1.0.0")
  cmd = Z.option(cmd, "--loud", "print the greeting in uppercase")
  Z.argument(cmd, "[title]", "the person or title to greet")

def greeting(title: String, loud: Bool) -> String:
  match loud:
    case True{}:
      String.to_upper("Hello, " ++ title ++ "!")
    case False{}:
      "Hello, " ++ title ++ "!"

def greeting_for(+invocation: Z.Invocation) -> String:
  title = Z.value.text(Z.arg(invocation, "title"), "world")
  loud = Z.value.enabled(Z.get(invocation, "loud"))
  greeting(title, loud)

def greet(invocation: Z.Invocation) -> IO(Unit):
  IO.print(greeting_for(invocation))

def main() -> IO(Unit):
  Z.run(command(), greet)
