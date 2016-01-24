
use "ponytest"
use "debug"
use "../src/async_parser"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestToken)
    test(_TestTokenFailure)
    test(_TestAnd)
    test(_TestAndMany)
    test(_TestAndFailure)
    test(_TestOr)
    test(_TestOrMany)
    test(_TestOrFailure)
    test(_TestMany)
    test(_TestAtLeastOne)

class iso _TestToken is UnitTest
  fun name():String => "token"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = Grammar(APToken(1))
    let parser = grammar.createParser()
    let res = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseSuccess)
    true

class iso _TestTokenFailure is UnitTest
  fun name():String => "token-failure"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = Grammar(APToken(1))
    let parser = grammar.createParser()
    let res = parser.acceptToken(ParserState(0, 2, "foo"))
    h.assert_true(res.status is ParseFailed)
    true

class iso _TestAnd is UnitTest
  fun name():String => "and"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val = recover Array[GrammarElement].init(APToken(1), 1) end
    let grammar = Grammar(APAnd(elements))
    let parser = grammar.createParser()
    let res = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseSuccess)
    true

class iso _TestAndMany is UnitTest
  fun name():String => "and-many"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val =
      recover
        Array[GrammarElement]()
          .push(APToken(1))
          .push(APToken(2))
          .push(APToken(3))
      end
    let grammar = Grammar(APAnd(elements))
    let parser = grammar.createParser()
    var res = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 1st continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(5, 2, "bar"))
    h.assert_true(res.status is ParseContinue, "expecting 2nd continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(18, 3, "end"))
    h.assert_true(res.status is ParseSuccess, "expecting end")
    true

class iso _TestAndFailure is UnitTest
  fun name():String => "and-failure"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val =
      recover
        Array[GrammarElement]()
          .push(APToken(1))
          .push(APToken(2))
          .push(APToken(3))
      end
    let grammar = Grammar(APAnd(elements))
    let parser = grammar.createParser()
    var res = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 1st continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(5, 3, "bar"))
    h.assert_true(res.status is ParseFailed, "expecting failure")
    true

class iso _TestOr is UnitTest
  fun name():String => "or"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val = recover Array[GrammarElement].init(APToken(1), 1) end
    let grammar = Grammar(APOr(elements))
    let parser = grammar.createParser()
    let res = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseSuccess)
    true

class iso _TestOrMany is UnitTest
  fun name():String => "or-many"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val =
      recover
        Array[GrammarElement]()
          .push(APToken(1))
          .push(APToken(2))
          .push(APToken(3))
      end
    let grammar = Grammar(APOr(elements))

    var parser = grammar.createParser()
    var res = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseSuccess, "expecting 1st success")

    parser = grammar.createParser()
    res = parser.acceptToken(ParserState(0, 2, "foo"))
    h.assert_true(res.status is ParseSuccess, "expecting 2nd success")

    parser = grammar.createParser()
    res = parser.acceptToken(ParserState(0, 3, "foo"))
    h.assert_true(res.status is ParseSuccess, "expecting 3rd success")
    true

class iso _TestOrFailure is UnitTest
  fun name():String => "or-failure"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val =
      recover
        Array[GrammarElement]()
          .push(APToken(1))
          .push(APToken(2))
          .push(APToken(3))
      end
    let grammar = Grammar(APOr(elements))
    let parser = grammar.createParser()
    var res = parser.acceptToken(ParserState(0, 8, "foo"))
    h.assert_true(res.status is ParseFailed)
    true


class iso _TestMany is UnitTest
  fun name():String => "many"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = Grammar(APMany(APToken(1)))
    var parser = grammar.createParser()
    var res = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 1st continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 2nd continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 3rd continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(0, 2, "bar"))
    h.assert_true(res.status is ParseSuccess, "expecting end success")

    parser = grammar.createParser()
    res = parser.acceptToken(ParserState(0, 2, "bar"))
    h.assert_true(res.status is ParseSuccess, "expecting starting end success")
    true


class iso _TestAtLeastOne is UnitTest
  fun name():String => "at-least-one"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = Grammar(APAtLeastOne(APToken(1)))
    var parser = grammar.createParser()
    var res = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 1st continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 2nd continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(res.status is ParseContinue, "expecting 3rd continue")
    res = (res.parser as TokenParser).acceptToken(ParserState(0, 2, "bar"))
    h.assert_true(res.status is ParseSuccess, "expecting end success")

    parser = grammar.createParser()
    res = parser.acceptToken(ParserState(0, 2, "bar"))
    h.assert_true(res.status is ParseFailed, "expecting starting end failure")
    true
