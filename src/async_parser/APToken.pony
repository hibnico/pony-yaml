
class val APToken is GrammarElement
  let tokenId: TokenId

  new val create(tokenId': TokenId) =>
    tokenId = tokenId'

  fun createParser(initialState: ParserState, onResult: OnParseResult): TokenParser =>
    _SingleTokenParser(tokenId, onResult)

class _SingleTokenParser is TokenParser
  let tokenId: TokenId
  let parentOnResult: OnParseResult

  new create(tokenId': TokenId, parentOnResult': OnParseResult) =>
    tokenId = tokenId'
    parentOnResult = parentOnResult'

  fun ref acceptToken(state: ParserState): ParseResult ? =>
    if state.tokenId == tokenId then
      return parentOnResult.onResult(ParseResult.success(state))
    else
      return parentOnResult.onResult(ParseResult.failed(state, "Expecting token \'" + tokenId.string()
        + "\' but got \'" + state.tokenId.string() + "\'"))
    end
