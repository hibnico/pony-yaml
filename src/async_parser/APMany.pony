
class APMany is GrammarElement
  let element: GrammarElement val

  new val create(element': GrammarElement val) =>
    element = element'

  fun createParser(state: ParserState, onResult: OnParseResult): TokenParser ? =>
    element.createParser(state, _ManyOnParseResult(element, onResult, false))

class _ManyOnParseResult is OnParseResult
  let parentOnResult: OnParseResult
  let element: GrammarElement val
  let atLeastOne: Bool
  var oneParsed: Bool = false

  new create(element': GrammarElement val, parentOnResult': OnParseResult, atLeastOne': Bool) =>
    element = element'
    parentOnResult = parentOnResult'
    atLeastOne = atLeastOne'

  fun ref onResult(res: ParseResult): ParseResult ? =>
    if res.status is ParseFailed then
      if (not atLeastOne or oneParsed) then
        return parentOnResult.onResult(ParseResult.success(res.state))
      else
        return parentOnResult.onResult(ParseResult.failed(res.state, "Expecting at least one element"))
      end
    end
    oneParsed = true
    let parser = element.createParser(res.state, this)
    ParseResult.cont(res.state, parser)


class APAtLeastOne is GrammarElement
  let element: GrammarElement val

  new val create(element': GrammarElement val) =>
    element = element'

  fun createParser(state: ParserState, onResult: OnParseResult): TokenParser ? =>
    element.createParser(state, _ManyOnParseResult(element, onResult, true))
