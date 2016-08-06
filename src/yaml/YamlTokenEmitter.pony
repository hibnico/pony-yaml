
interface tag YamlTokenEmitter
  be emit(token: YamlToken)

actor YamlTokenCollector is YamlTokenEmitter
  let tokens: Array[YamlToken] = Array[YamlToken].create()
  be emit(token: YamlToken) =>
    tokens.push(token)
