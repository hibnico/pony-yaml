
type TokenId is U16

class val ParserState
  let tokenId: TokenId
  let value: String
  let position: U8

  new val start() =>
    position = 0
    tokenId = 0
    value = ""

  new val create(position': U8, tokenId': TokenId, value': String) =>
    position = position'
    tokenId = tokenId'
    value = value'


primitive ParseSuccess
primitive ParseContinue
primitive ParseFailed
type ParseStatus is (ParseSuccess | ParseContinue | ParseFailed)


class ParseResult
  let status: ParseStatus
  let parser: (TokenParser | None)
  let state: ParserState
  let errorMessage: Stringable

  new success(state': ParserState) =>
    status = ParseSuccess
    state = state'
    parser = None
    errorMessage = None

  new cont(state': ParserState, parser': TokenParser) =>
    status = ParseContinue
    parser = parser'
    state = state'
    errorMessage = None

  new failed(state': ParserState, message': String) =>
    status = ParseFailed
    state = state'
    parser = None
    errorMessage = message'


interface val GrammarElement
  fun createParser(initialState: ParserState, onResult: OnParseResult): TokenParser ?

interface TokenParser
  fun ref acceptToken(state: ParserState): ParseResult ?

interface OnParseResult
  fun ref onResult(res: ParseResult): ParseResult ?


class PassOnOnParseResult is OnParseResult
  fun ref onResult(res: ParseResult): ParseResult => res

class val Grammar
  let root: GrammarElement

  new val create(root': GrammarElement val) =>
    root = root'

  fun createParser(): TokenParser ? =>
    root.createParser(ParserState.start(), PassOnOnParseResult.create())



class val APToken is GrammarElement
  let tokenId: TokenId

  new val create(tokenId': TokenId) =>
    tokenId = tokenId'

  fun createParser(initialState: ParserState, onResult: OnParseResult): TokenParser =>
    _SingleTokenParser.create(tokenId, onResult)

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



class APOr is GrammarElement
  let elements: Array[GrammarElement] val

  new val create(elements': Array[GrammarElement] val) =>
    elements = elements'

  fun createParser(state: ParserState, onResult: OnParseResult): TokenParser ? =>
    elements(0).createParser(state, _OrOnParseResult.create(state, elements, onResult))

class _OrOnParseResult is OnParseResult
  let parentOnResult: OnParseResult
  let elements: Array[GrammarElement] val
  var currentElement: USize = 0
  let initialState: ParserState

  new create(initialState': ParserState, elements': Array[GrammarElement] val, parentOnResult': OnParseResult) =>
    initialState = initialState'
    elements = elements'
    parentOnResult = parentOnResult'

  fun ref onResult(res: ParseResult): ParseResult ? =>
    if res.status is ParseSuccess then
      return parentOnResult.onResult(res)
    end
    currentElement = currentElement + 1
    if currentElement < elements.size() then
      let parser = elements(currentElement).createParser(initialState, this)
      return parser.acceptToken(initialState)
    end
    parentOnResult.onResult(res)


class APAnd is GrammarElement
  let elements: Array[GrammarElement] val

  new val create(elements': Array[GrammarElement] val) =>
    elements = elements'

  fun createParser(state: ParserState, onResult: OnParseResult): TokenParser ? =>
    elements(0).createParser(state, _AndOnParseResult.create(elements, onResult))

class _AndOnParseResult is OnParseResult
  let parentOnResult: OnParseResult
  let elements: Array[GrammarElement] val
  var currentElement: USize = 0

  new create(elements': Array[GrammarElement] val, parentOnResult': OnParseResult) =>
    elements = elements'
    parentOnResult = parentOnResult'

  fun ref onResult(res: ParseResult): ParseResult ? =>
    if res.status is ParseFailed then
      return parentOnResult.onResult(res)
    end
    currentElement = currentElement + 1
    if currentElement < elements.size() then
      let parser = elements(currentElement).createParser(res.state, this)
      return ParseResult.cont(res.state, parser)
    end
    parentOnResult.onResult(ParseResult.success(res.state))
