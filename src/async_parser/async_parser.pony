
interface val Token
  fun eq(token: Token): Bool
  fun toString(): String

class val StartToken is Token
  fun eq(token: Token): Bool =>
    false // TODO

  fun toString(): String =>
    "START"


class val StringToken is Token
  let token: String

  new val create(token': String) =>
    token = token'

  fun eq(token': Token): Bool =>
    false // TODO

  fun toString(): String =>
    "\"" + token + "\""


class val ParserState
  let token: Token
  let position: U8

  new val start() =>
    position = 0
    token = StartToken

  new val create(position': U8, token': Token) =>
    position = position'
    token = token'

primitive ParseSuccess
primitive ParseContinue
primitive ParseFailed
type ParseStatus is (ParseSuccess | ParseContinue | ParseFailed)


class ParseResult
  let status: ParseStatus
  let parser: Maybe[TokenParser]
  let state: ParserState
  let errorMessage: Stringable

  new success(state': ParserState) =>
    status = ParseSuccess
    state = state'
    parser = Maybe[TokenParser].none()
    errorMessage = None

  new cont(state': ParserState, parser': TokenParser) =>
    status = ParseContinue
    parser = Maybe[TokenParser](parser')
    state = state'
    errorMessage = None

  new failed(state': ParserState, message': String) =>
    status = ParseFailed
    state = state'
    parser = Maybe[TokenParser].none()
    errorMessage = message'

interface GrammarElement
  fun createParser(initialState: ParserState, onResult: OnParseResult): TokenParser ?

interface TokenParser
  fun ref acceptToken(state: ParserState): ParseResult ?

interface OnParseResult
  fun ref onResult(res: ParseResult): ParseResult ?


class PassOnOnParseResult is OnParseResult
  fun ref onResult(res: ParseResult): ParseResult => res

class Grammar
  let element: GrammarElement

  new create(element': GrammarElement) =>
    element = element'

  fun createParser(): TokenParser ? =>
    element.createParser(ParserState.start(), PassOnOnParseResult.create())



class APToken is GrammarElement
  let expectedToken: Token

  new create(token': Token) =>
    expectedToken = token'

  fun createParser(initialState: ParserState, onResult: OnParseResult): TokenParser =>
    _SingleTokenParser.create(expectedToken, onResult)

class _SingleTokenParser is TokenParser
  let expectedToken: Token
  let parentOnResult: OnParseResult

  new create(token': Token, parentOnResult': OnParseResult) =>
    expectedToken = token'
    parentOnResult = parentOnResult'

  fun ref acceptToken(state: ParserState): ParseResult ? =>
    if state.token == expectedToken then
      return parentOnResult.onResult(ParseResult.success(state))
    else
      return parentOnResult.onResult(ParseResult.failed(state, "Expecting token \'" + expectedToken.toString()
        + "\' but got \'" + state.token.toString() + "\'"))
    end



class APOr is GrammarElement
  let elements: Array[GrammarElement] val

  new create(elements': Array[GrammarElement] val) =>
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

  new create(elements': Array[GrammarElement] val) =>
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
