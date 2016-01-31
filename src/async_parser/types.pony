
use "debug"

interface val TokenType is (Equatable[TokenType] & Stringable)
  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ => "tokentype".string(fmt)

interface val Token is Stringable
  fun getType(): TokenType
  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ => getType().string(fmt)

primitive NoTokenType is TokenType
primitive NoToken is Token
  fun getType(): TokenType => NoTokenType

class val ParserState
  let token: Token

  new val start() =>
    token = NoToken

  new val create(token': Token) =>
    token = token'


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
