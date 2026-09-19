import Base
import ../../best/best.bend as Best
import ./parser_test.bend as Parser

def main() -> IO(Unit):
  Best.run(Parser.suite())
