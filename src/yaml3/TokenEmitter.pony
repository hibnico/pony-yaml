
interface tag TokenEmitter
  be emit(token: YamlToken)

actor TokenCollector is TokenEmitter
  let tokens: Array[YamlToken] = Array[YamlToken].create()
  be emit(token: YamlToken) =>
    tokens.push(token)
