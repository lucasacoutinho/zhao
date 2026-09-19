import Base

def choose(condition: Bool, yes: String, no: String) -> String:
  match condition:
    case True{}:
      yes
    case False{}:
      no

def words.push(head: String, rest: List<&2, String>) -> List<&2, String>:
  match head:
    case SNil{}:
      rest
    case SCon{c, tail}:
      SCon{c, tail} <> rest

def words.go(text: String, current: String, found: List<&2, String>) -> List<&2, String>:
  match text:
    case SNil{}:
      List.reverse(&2, String, words.push(String.reverse(current), found))
    case SCon{' ', tail}:
      words.go(tail, "", words.push(String.reverse(current), found))
    case SCon{',', tail}:
      words.go(tail, "", words.push(String.reverse(current), found))
    case SCon{'\t', tail}:
      words.go(tail, "", words.push(String.reverse(current), found))
    case SCon{c, tail}:
      words.go(tail, SCon{c, current}, found)

def words(text: String) -> List<&2, String>:
  words.go(text, "", [])

def split_equal.go(text: String, prefix: String) -> String & Maybe<&2, String>:
  match text:
    case SNil{}:
      (String.reverse(prefix), None{})
    case SCon{'=', tail}:
      (String.reverse(prefix), Some{tail})
    case SCon{c, tail}:
      split_equal.go(tail, SCon{c, prefix})

def split_equal(text: String) -> String & Maybe<&2, String>:
  split_equal.go(text, "")

def option_like(text: String) -> Bool:
  match text:
    case SCon{'-', SCon{_, _}}:
      True{}
    case _:
      False{}

def chars_valid(text: String) -> Bool:
  match text:
    case SNil{}:
      True{}
    case SCon{+c, tail}:
      (Char.is_alpha(c) || Char.is_digit(c) || Char.is_eq(c, '-')) && chars_valid(tail)

def identifier(+text: String) -> Bool:
  Bool.not(String.is_empty(text)) && chars_valid(text)

def unwrap(+text: String) -> String:
  String.take(String.drop(text, 1n), Nat.sub(String.length(text), 2n))

def camel(text: String) -> String:
  match text:
    case SNil{}:
      ""
    case SCon{'-', SCon{c, tail}}:
      SCon{Char.to_upper(c), camel(tail)}
    case SCon{c, tail}:
      SCon{c, camel(tail)}

def strings(xs: List<String>) -> List<&2, String>:
  match xs:
    case Nil{}:
      []
    case h <> t:
      h <> strings(t)

def weight(xs: List<&2, String>) -> Nat:
  match xs:
    case Nil{}:
      1n
    case h <> t:
      Nat.add(1n+String.length(h), weight(t))

def number.end(state: Nat) -> Bool:
  match state:
    case 1n:
      True{}
    case 3n:
      True{}
    case 6n:
      True{}
    case _:
      False{}

def number.transition(state: Nat, digit: Bool, dot: Bool, exponent: Bool, sign: Bool) -> Nat:
  match state digit dot exponent sign:
    case 0n True{} _ _ _:
      1n
    case 0n False{} True{} _ _:
      7n
    case 1n True{} _ _ _:
      1n
    case 1n False{} True{} _ _:
      2n
    case 1n False{} False{} True{} _:
      4n
    case 2n True{} _ _ _:
      3n
    case 3n True{} _ _ _:
      3n
    case 3n False{} False{} True{} _:
      4n
    case 4n True{} _ _ _:
      6n
    case 4n False{} False{} False{} True{}:
      5n
    case 5n True{} _ _ _:
      6n
    case 6n True{} _ _ _:
      6n
    case 7n True{} _ _ _:
      3n
    case _ _ _ _ _:
      8n

def number.next(+c: Char, state: Nat) -> Nat:
  number.transition(state, Char.is_digit(c), Char.is_eq(c, '.'), Char.is_eq(c, 'e'), Char.is_eq(c, '+') || Char.is_eq(c, '-'))

def number.scan(text: String, state: Nat) -> Bool:
  match text:
    case SNil{}:
      number.end(state)
    case SCon{c, tail}:
      number.scan(tail, number.next(c, state))

def negative_number(text: String) -> Bool:
  match text:
    case SCon{'-', tail}:
      number.scan(tail, 0n)
    case _:
      False{}
