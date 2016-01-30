use "ponytest"
use "debug"
use "async_parser"

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
