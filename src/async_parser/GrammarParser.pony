
class GrammarParser

  var parser: TokenParser

  new create(grammar: GrammarElement val) ? =>
    parser = grammar.createParser(ParserState.start(), PassOnOnParseResult.create())

  fun ref acceptToken(state: ParserState): ParseStatus ? =>
    let res = parser.acceptToken(state)
    if (not ((res.parser) is None)) then
      parser = res.parser as TokenParser
    end
    res.status
