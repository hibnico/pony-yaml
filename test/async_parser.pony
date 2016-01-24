
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
    let grammar = APToken(1)
    let parser = GrammarParser(grammar)
    let status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseSuccess)
    true

class iso _TestTokenFailure is UnitTest
  fun name():String => "token-failure"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = APToken(1)
    let parser = GrammarParser(grammar)
    let status = parser.acceptToken(ParserState(0, 2, "foo"))
    h.assert_true(status is ParseFailed)
    true

class iso _TestAnd is UnitTest
  fun name():String => "and"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val = recover Array[GrammarElement].init(APToken(1), 1) end
    let grammar = APAnd(elements)
    let parser = GrammarParser(grammar)
    let status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseSuccess)
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
    let grammar = APAnd(elements)
    let parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseContinue, "expecting 1st continue")
    status = parser.acceptToken(ParserState(5, 2, "bar"))
    h.assert_true(status is ParseContinue, "expecting 2nd continue")
    status = parser.acceptToken(ParserState(18, 3, "end"))
    h.assert_true(status is ParseSuccess, "expecting end")
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
    let grammar = APAnd(elements)
    let parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseContinue, "expecting 1st continue")
    status = parser.acceptToken(ParserState(5, 3, "bar"))
    h.assert_true(status is ParseFailed, "expecting failure")
    true

class iso _TestOr is UnitTest
  fun name():String => "or"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val = recover Array[GrammarElement].init(APToken(1), 1) end
    let grammar = APOr(elements)
    let parser = GrammarParser(grammar)
    let status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseSuccess)
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
    let grammar = APOr(elements)

    var parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseSuccess, "expecting 1st success")

    parser = GrammarParser(grammar)
    status = parser.acceptToken(ParserState(0, 2, "foo"))
    h.assert_true(status is ParseSuccess, "expecting 2nd success")

    parser = GrammarParser(grammar)
    status = parser.acceptToken(ParserState(0, 3, "foo"))
    h.assert_true(status is ParseSuccess, "expecting 3rd success")
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
    let grammar = APOr(elements)
    let parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(0, 8, "foo"))
    h.assert_true(status is ParseFailed)
    true


class iso _TestMany is UnitTest
  fun name():String => "many"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = APMany(APToken(1))
    var parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseContinue, "expecting 1st continue")
    status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseContinue, "expecting 2nd continue")
    status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseContinue, "expecting 3rd continue")
    status = parser.acceptToken(ParserState(0, 2, "bar"))
    h.assert_true(status is ParseSuccess, "expecting end success")

    parser = GrammarParser(grammar)
    status = parser.acceptToken(ParserState(0, 2, "bar"))
    h.assert_true(status is ParseSuccess, "expecting starting end success")
    true


class iso _TestAtLeastOne is UnitTest
  fun name():String => "at-least-one"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = APAtLeastOne(APToken(1))
    var parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseContinue, "expecting 1st continue")
    status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseContinue, "expecting 2nd continue")
    status = parser.acceptToken(ParserState(0, 1, "foo"))
    h.assert_true(status is ParseContinue, "expecting 3rd continue")
    status = parser.acceptToken(ParserState(0, 2, "bar"))
    h.assert_true(status is ParseSuccess, "expecting end success")

    parser = GrammarParser(grammar)
    status = parser.acceptToken(ParserState(0, 2, "bar"))
    h.assert_true(status is ParseFailed, "expecting starting end failure")
    true
