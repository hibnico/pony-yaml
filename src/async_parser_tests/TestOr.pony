use "ponytest"
use "debug"
use "async_parser"

class iso _TestOr is UnitTest
  fun name():String => "or"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val = recover Array[GrammarElement].init(APToken(TestTokenType1), 1) end
    let grammar = APOr(elements)
    let parser = GrammarParser(grammar)
    let status = parser.acceptToken(ParserState(TestToken(TestTokenType1)))
    h.assert_true(status is ParseSuccess)
    true

class iso _TestOrMany is UnitTest
  fun name():String => "or-many"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val =
      recover
        Array[GrammarElement]()
          .push(APToken(TestTokenType1))
          .push(APToken(TestTokenType2))
          .push(APToken(TestTokenType3))
      end
    let grammar = APOr(elements)

    var parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(TestToken(TestTokenType1)))
    h.assert_true(status is ParseSuccess, "expecting 1st success")

    parser = GrammarParser(grammar)
    status = parser.acceptToken(ParserState(TestToken(TestTokenType2)))
    h.assert_true(status is ParseSuccess, "expecting 2nd success")

    parser = GrammarParser(grammar)
    status = parser.acceptToken(ParserState(TestToken(TestTokenType3)))
    h.assert_true(status is ParseSuccess, "expecting 3rd success")
    true

class iso _TestOrFailure is UnitTest
  fun name():String => "or-failure"

  fun apply(h: TestHelper): TestResult ? =>
    let elements: Array[GrammarElement] val =
      recover
        Array[GrammarElement]()
          .push(APToken(TestTokenType1))
          .push(APToken(TestTokenType2))
          .push(APToken(TestTokenType3))
      end
    let grammar = APOr(elements)
    let parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(TestToken(TestTokenType4)))
    h.assert_true(status is ParseFailed)
    true
