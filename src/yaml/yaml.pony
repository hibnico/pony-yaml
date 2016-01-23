
actor Main
  new create(env: Env) =>
    env.out.print("start")



interface YamlHandler
  fun startDocument()
  fun endDocument()
