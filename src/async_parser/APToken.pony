
class val APToken is GrammarElement
  let tokenType: TokenType

  new val create(tokenType': TokenType) =>
    tokenType = tokenType'

  fun createParser(initialState: ParserState, onResult: OnParseResult): TokenParser =>
    _SingleTokenParser(tokenType, onResult)

class _SingleTokenParser is TokenParser
  let tokenType: TokenType
  let parentOnResult: OnParseResult

  new create(tokenType': TokenType, parentOnResult': OnParseResult) =>
    tokenType = tokenType'
    parentOnResult = parentOnResult'

  fun ref acceptToken(state: ParserState): ParseResult ? =>
    if state.token.getType() == tokenType then
      return parentOnResult.onResult(ParseResult.success(state))
    else
      return parentOnResult.onResult(ParseResult.failed(state, "Expecting token type \'" + tokenType.string()
        + "\' but got \'" + state.token.string() + "\'"))
    end
