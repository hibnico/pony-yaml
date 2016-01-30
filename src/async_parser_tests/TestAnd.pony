use "ponytest"
use "debug"
use "async_parser"

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
