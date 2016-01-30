
use "debug"

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
