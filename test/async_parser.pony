
use "ponytest"
use "../src/async_parser"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestToken)

class iso _TestToken is UnitTest
  fun name():String => "token"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = Grammar.create(APToken.create(StringToken.create("foo")))
    let parser = grammar.createParser()
    let res = parser.acceptToken(ParserState.create(0, StringToken.create("foo")))
    h.assert_true(res.status is ParseSuccess)
    true

class iso _TestAnd is UnitTest
  fun name():String => "and"

  fun apply(h: TestHelper): TestResult ? =>
    let elements = Array[GrammarElement].init(APToken.create(StringToken.create("foo")), 1)
    let grammar = Grammar.create(APAnd.create(elements))
    let parser = grammar.createParser()
    let res = parser.acceptToken(ParserState.create(0, StringToken.create("foo")))
    h.assert_true(res.status is ParseSuccess)
    true

class iso _TestOr is UnitTest
  fun name():String => "or"

  fun apply(h: TestHelper): TestResult ? =>
    h.assert_eq[U32](2, 4 - 2)
    true
