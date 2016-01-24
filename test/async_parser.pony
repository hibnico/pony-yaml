
use "ponytest"
use "../src/async_parser"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestToken)
    test(_TestAnd)
    test(_TestAnd2)

class iso _TestToken is UnitTest
  fun name():String => "token"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = Grammar.create(APToken.create(1))
    let parser = grammar.createParser()
    let res = parser.acceptToken(ParserState.create(0, 1, "foo"))
    h.assert_true(res.status is ParseSuccess)
    true

class iso _TestAnd is UnitTest
  fun name():String => "and"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val = recover Array[GrammarElement].init(APToken.create(1), 1) end
    let grammar = Grammar.create(APAnd.create(elements))
    let parser = grammar.createParser()
    let res = parser.acceptToken(ParserState.create(0, 1, "foo"))
    h.assert_true(res.status is ParseSuccess)
    true

class iso _TestAnd2 is UnitTest
  fun name():String => "and2"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val =
      recover
        Array[GrammarElement].create()
          .push(APToken.create(1))
          .push(APToken.create(2))
          .push(APToken.create(3))
      end
    let grammar = Grammar.create(APAnd.create(elements))
    let parser = grammar.createParser()
    var res = parser.acceptToken(ParserState.create(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 1st continue")
    res = (res.parser as TokenParser).acceptToken(ParserState.create(5, 2, "bar"))
    h.assert_true(res.status is ParseContinue, "expecting 2nd continue")
    res = (res.parser as TokenParser).acceptToken(ParserState.create(18, 3, "end"))
    h.assert_true(res.status is ParseSuccess, "expecting end")
    true
