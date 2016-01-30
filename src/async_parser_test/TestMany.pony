use "ponytest"
use "debug"
use "async_parser"

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
