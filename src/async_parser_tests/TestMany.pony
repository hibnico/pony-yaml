use "ponytest"
use "debug"
use "async_parser"

class iso _TestMany is UnitTest
  fun name():String => "many"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = APMany(APToken(TestTokenType1))
    var parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(TestToken(TestTokenType1)))
    h.assert_true(status is ParseContinue, "expecting 1st continue")
    status = parser.acceptToken(ParserState(TestToken(TestTokenType1)))
    h.assert_true(status is ParseContinue, "expecting 2nd continue")
    status = parser.acceptToken(ParserState(TestToken(TestTokenType1)))
    h.assert_true(status is ParseContinue, "expecting 3rd continue")
    status = parser.acceptToken(ParserState(TestToken(TestTokenType2)))
    h.assert_true(status is ParseSuccess, "expecting end success")

    parser = GrammarParser(grammar)
    status = parser.acceptToken(ParserState(TestToken(TestTokenType2)))
    h.assert_true(status is ParseSuccess, "expecting starting end success")
    true


class iso _TestAtLeastOne is UnitTest
  fun name():String => "at-least-one"

  fun apply(h: TestHelper): TestResult ? =>
    let grammar = APAtLeastOne(APToken(TestTokenType1))
    var parser = GrammarParser(grammar)
    var status = parser.acceptToken(ParserState(TestToken(TestTokenType1)))
    h.assert_true(status is ParseContinue, "expecting 1st continue")
    status = parser.acceptToken(ParserState(TestToken(TestTokenType1)))
    h.assert_true(status is ParseContinue, "expecting 2nd continue")
    status = parser.acceptToken(ParserState(TestToken(TestTokenType1)))
    h.assert_true(status is ParseContinue, "expecting 3rd continue")
    status = parser.acceptToken(ParserState(TestToken(TestTokenType2)))
    h.assert_true(status is ParseSuccess, "expecting end success")

    parser = GrammarParser(grammar)
    status = parser.acceptToken(ParserState(TestToken(TestTokenType2)))
    h.assert_true(status is ParseFailed, "expecting starting end failure")
    true
