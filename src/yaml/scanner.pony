use "collections"

/** Token types. */

/** An empty token. */
primitive YAML_NO_TOKEN is TokenType

/** A STREAM-START token. */
primitive YAML_STREAM_START_TOKEN is TokenType
/** A STREAM-END token. */
primitive YAML_STREAM_END_TOKEN is TokenType

/** A VERSION-DIRECTIVE token. */
primitive YAML_VERSION_DIRECTIVE_TOKEN is TokenType
/** A TAG-DIRECTIVE token. */
primitive YAML_TAG_DIRECTIVE_TOKEN is TokenType
/** A DOCUMENT-START token. */
primitive YAML_DOCUMENT_START_TOKEN is TokenType
/** A DOCUMENT-END token. */
primitive YAML_DOCUMENT_END_TOKEN is TokenType

/** A BLOCK-SEQUENCE-START token. */
primitive YAML_BLOCK_SEQUENCE_START_TOKEN is TokenType
/** A BLOCK-SEQUENCE-END token. */
primitive YAML_BLOCK_MAPPING_START_TOKEN is TokenType
/** A BLOCK-END token. */
primitive YAML_BLOCK_END_TOKEN is TokenType

/** A FLOW-SEQUENCE-START token. */
primitive YAML_FLOW_SEQUENCE_START_TOKEN is TokenType
/** A FLOW-SEQUENCE-END token. */
primitive YAML_FLOW_SEQUENCE_END_TOKEN is TokenType
/** A FLOW-MAPPING-START token. */
primitive YAML_FLOW_MAPPING_START_TOKEN is TokenType
/** A FLOW-MAPPING-END token. */
primitive YAML_FLOW_MAPPING_END_TOKEN is TokenType

/** A BLOCK-ENTRY token. */
primitive YAML_BLOCK_ENTRY_TOKEN is TokenType
/** A FLOW-ENTRY token. */
primitive YAML_FLOW_ENTRY_TOKEN is TokenType
/** A KEY token. */
primitive YAML_KEY_TOKEN is TokenType
/** A VALUE token. */
primitive YAML_VALUE_TOKEN is TokenType

/** An ALIAS token. */
primitive YAML_ALIAS_TOKEN is TokenType
/** An ANCHOR token. */
primitive YAML_ANCHOR_TOKEN is TokenType
/** A TAG token. */
primitive YAML_TAG_TOKEN is TokenType
/** A SCALAR token. */
primitive YAML_SCALAR_TOKEN is TokenType


trait val _YamlTokenData

primitive _NoYamlTokenData is _YAMLTokenData

/** The stream start (for @c YAML_STREAM_START_TOKEN). */
class _YamlStreamStartTokenData is _YamlTokenData
  /** The stream encoding. */
  var encoding: _YamlEncoding

/** The alias (for @c YAML_ALIAS_TOKEN). */
class _YamlAliasTokenData is _YamlTokenData
  /** The alias value. */
  let value: _YamlChar

/** The anchor (for @c YAML_ANCHOR_TOKEN). */
class _YamlAnchorTokenData is _YamlTokenData
  /** The anchor value. */
  let value: _YamlChar

/** The tag (for @c YAML_TAG_TOKEN). */
class _YamlTagTokenData is _YamlTokenData
  /** The tag handle. */
  let handle: _YamlChar
  /** The tag suffix. */
  let suffix: _YamlChar

/** The scalar value (for @c YAML_SCALAR_TOKEN). */
class _YamlScalarTokenData is _YamlTokenData
  /** The scalar value. */
  let value: _YamlChar
  /** The length of the scalar value. */
  let length: USize
  /** The scalar style. */
  let style: _YamlScalarStyle

/** The version directive (for @c YAML_VERSION_DIRECTIVE_TOKEN). */
class _YamlVersionDirectiveTokenData is _YamlTokenData
  /** The major version number. */
  let major: U16
  /** The minor version number. */
  let minor: U16

/** The tag directive (for @c YAML_TAG_DIRECTIVE_TOKEN). */
class _YamlTagDirectiveTokenData is _YamlTokenData
  /** The tag handle. */
  let handle: _YamlChar
  /** The tag prefix. */
  let prefix: _YamlChar

class _YAMLToken is Token
  /** The token type. */
  let tokenType: TokenType
  /** The beginning of the token. */
  let start_mark: _YamlMark
  /** The end of the token. */
  let end_mark: _YamlMark
  /** The token data. */
  let data: _YAMLTokenData

  new val create(tokenType': TokenType, start_mark': _YamlMark, end_mark': _YamlMark,
                  data': _YAMLTokenData = _NoYamlTokenData) =>
    tokenType = tokenType'
    start_mark = start_mark'
    end_mark = end_mark'
    data = data'

  fun getType(): TokenType => tokenType

class _YamlMark
  /** The position index. */
  var index: USize = 0
  /** The position line. */
  var line: USize = 0
  /** The position column. */
  var column: USize = 0


class _YamlSimpleKey
  /** Is a simple key possible? */
  var possible: Bool = false
  /** Is a simple key required? */
  var required: Bool = false
  /** The number of the token. */
  var token_number: USize = 0
  /** The position mark. */
  var mark: _YamlMark = _YamlMark.create()


class _YamlError
    /** Error type. */
    yaml_error_type_t error;
    /** Error description. */
    const char *problem;
    /** The byte about which the problem occured. */
    size_t problem_offset;
    /** The problematic value (@c -1 is none). */
    int problem_value;
    /** The problem position. */
    yaml_mark_t problem_mark;
    /** The error context. */
    const char *context;
    /** The context position. */
    yaml_mark_t context_mark;


class _YamReader
  /** Read handler. */
  yaml_read_handler_t *read_handler;
  /** A pointer for passing to the read handler. */
  void *read_handler_data;
  /** Standard (string or file) input data. */
  union {
      /** String input data. */
      struct {
          /** The string start pointer. */
          const unsigned char *start;
          /** The string end pointer. */
          const unsigned char *end;
          /** The string current position. */
          const unsigned char *current;
      } string;

      /** File input data. */
      FILE *file;
  } input;
  /** EOF flag */
  int eof;
  /** The working buffer. */
  struct {
      /** The beginning of the buffer. */
      yaml_char_t *start;
      /** The end of the buffer. */
      yaml_char_t *end;
      /** The current position of the buffer. */
      yaml_char_t *pointer;
      /** The last filled position of the buffer. */
      yaml_char_t *last;
  } buffer;
  /* The number of unread characters in the buffer. */
  size_t unread;
  /** The raw buffer. */
  struct {
      /** The beginning of the buffer. */
      unsigned char *start;
      /** The end of the buffer. */
      unsigned char *end;
      /** The current position of the buffer. */
      unsigned char *pointer;
      /** The last filled position of the buffer. */
      unsigned char *last;
  } raw_buffer;
  /** The input encoding. */
  yaml_encoding_t encoding;
  /** The offset of the current position (in bytes). */
  var offset: USize
  /** The mark of the current position. */
  var mark: _YamlMark


class _YamlParser
  /** The parser states stack. */
  struct {
      /** The beginning of the stack. */
      yaml_parser_state_t *start;
      /** The end of the stack. */
      yaml_parser_state_t *end;
      /** The top of the stack. */
      yaml_parser_state_t *top;
  } states;

  /** The current parser state. */
  yaml_parser_state_t state;

  /** The stack of marks. */
  struct {
      /** The beginning of the stack. */
      yaml_mark_t *start;
      /** The end of the stack. */
      yaml_mark_t *end;
      /** The top of the stack. */
      yaml_mark_t *top;
  } marks;

  /** The list of TAG directives. */
  struct {
      /** The beginning of the list. */
      yaml_tag_directive_t *start;
      /** The end of the list. */
      yaml_tag_directive_t *end;
      /** The top of the list. */
      yaml_tag_directive_t *top;
  } tag_directives;


class _YamlDumper
  /** The alias data. */
  struct {
      /** The beginning of the list. */
      yaml_alias_data_t *start;
      /** The end of the list. */
      yaml_alias_data_t *end;
      /** The top of the list. */
      yaml_alias_data_t *top;
  } aliases;
  /** The currently parsed document. */
  yaml_document_t *document;

type FetchResult is (_YamlError | _NeedBytes | None)
type ScanResult is (_YamlError | _NeedBytes | Token)

#define MAX_NUMBER_LENGTH   9

class _YamlScanner
  /** Have we started to scan the input stream? */
  var _stream_start_produced: Bool
  /** Have we reached the end of the input stream? */
  var _stream_end_produced: Bool
  /** The number of unclosed '[' and '{' indicators. */
  var _flow_level: U8

  /** The tokens queue. */
  // struct {
  //     /** The beginning of the tokens queue. */
  //     yaml_token_t *start;
  //     /** The end of the tokens queue. */
  //     yaml_token_t *end;
  //     /** The head of the tokens queue. */
  //     yaml_token_t *head;
  //     /** The tail of the tokens queue. */
  //     yaml_token_t *tail;
  // } tokens;

  /** The number of tokens fetched from the queue. */
  // size_t tokens_parsed;

  /* Does the tokens queue contain a token ready for dequeueing. */
  // int tokenbuffer.cacheable;

  /** The indentation levels stack. */
  var indents: Array[U16]

  /** The current indentation level. */
  var _indent: U16

  /** May a simple key occur at the current position? */
  var _simple_key_allowed: Bool

  /** The stack of simple keys. */
  var simple_keys: Array[_YamlSimpleKey]

  fun _skip() =>
    mark.index = mark.index + 1
    mark.column = mark.column + 1
    unread = unread - 1
    buffer.move()

  fun _skipLine() =>
    if buffer.isCrlf() then
      mark.index = mark.index + 2
      mark.column = 0
      mark.line = mark.line + 1
      unread = unread - 2
      buffer.move(2)
    elseif buffer.isBreak() then
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
      unread = unread - 1
      buffer.move()
    end

  fun _read(): U8 =>
    mark.index = mark.index + 1
    mark.column = mark.column + 1
    unread = unread - 1
    buffer.get()

  fun _readLine(string: String) =>
    if buffer.checkAt('\r', 0) and buffer.checkAt('\n', 1) then        /* CR LF -> LF */
      string.push('\n')
      buffer.pointer = buffer.pointer + 2
      mark.index = mark.index + 2
      mark.column = 0
      mark.line = mark.line + 1
      unread = unread - 2
    elseif buffer.checkAt('\r', 0) or buffer.checkAt('\n',0) then         /* CR|LF -> LF */
      string.push('\n')
      buffer.pointer = buffer.pointer + 1
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
      unread = unread - 1
    elseif buffer.checkAt('\xC2', 0) and buffer.checkAt('\x85', 1) then       /* NEL -> LF */
      string.push('\n')
      buffer.pointer = buffer.pointer + 2
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
      unread = unread - 1
    elseif buffer.checkAt('\xE2',0) and buffer.checkAt('\x80',1)
          and (buffer.checkAt('\xA8',2) or buffer.checkAt('\xA9',2)) then        /* LS|PS -> LS|PS */
      string.push(buffer.pointer++)
      string.push(buffer.pointer++)
      string.push(buffer.pointer++)
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
      unread = unread - 1
    end

  fun fetch_next_token(): FetchResult =>
    /* Ensure that the buffer is initialized. */
    if not buffer.cache(1) then
      return _NeedBytes
    end

    /* Check if we just started scanning.  Fetch STREAM-START then. */
    if not _stream_start_produced then
      return _fetch_stream_start()
    end

    /* Eat whitespaces and comments until we reach the next token. */
    var res = _scan_to_next_token()
    if not res is None then
      return res
    end

    /* Remove obsolete potential simple keys. */
    res = _stale_simple_keys()
    if not res is None  then
      return res
    end

    /* Check the indentation level against the current column. */
    _unroll_indent(mark.column)

    /*
     * Ensure that the buffer contains at least 4 characters.  4 is the length
     * of the longest indicators ('--- ' and '... ').
    */
    if not buffer.cache(4) then
      return _NeedBytes
    end

    /* Is it the end of the stream? */
    if buffer.isZ() then
      return _fetch_stream_end()
    end

    /* Is it a directive? */
    if mark.column == 0 and buffer.check('%') then
      return _fetch_directive()
    end

    /* Is it the document start indicator? */
    if mark.column == 0
            and buffer.checkAt('-', 0)
            and buffer.checkAt('-', 1)
            and buffer.checkAt('-', 2)
            and buffer.isBlankZAt(3) then
      return _fetch_document_indicator(YAML_DOCUMENT_START_TOKEN)
    end

    /* Is it the document end indicator? */
    if mark.column == 0
            and buffer.checkAt('.', 0)
            and buffer.checkAt('.', 1)
            and buffer.checkAt('.', 2)
            and buffer.isBlankZAt(3) then
      return _fetch_document_indicator(YAML_DOCUMENT_END_TOKEN)
    end

    /* Is it the flow sequence start indicator? */
    if buffer.check('[') then
      return _fetch_flow_collection_start(YAML_FLOW_SEQUENCE_START_TOKEN)
    end

    /* Is it the flow mapping start indicator? */
    if buffer.check('{') then
      return _fetch_flow_collection_start(YAML_FLOW_MAPPING_START_TOKEN)
    end

    /* Is it the flow sequence end indicator? */
    if buffer.check(']') then
      return yaml_parser_fetch_flow_collection_end(YAML_FLOW_SEQUENCE_END_TOKEN)
    end

    /* Is it the flow mapping end indicator? */
    if buffer.check('}') then
      return _fetch_flow_collection_end(YAML_FLOW_MAPPING_END_TOKEN)
    end

    /* Is it the flow entry indicator? */
    if buffer.check(',') then
      return _fetch_flow_entry()
    end

    /* Is it the block entry indicator? */
    if buffer.check('-') and buffer.isBlankZAt(1) then
      return _fetch_block_entry()
    end

    /* Is it the key indicator? */
    if buffer.check('?') and (flow_level or buffer.isBlankZAt(1)) then
      return _fetch_key()
    end

    /* Is it the value indicator? */
    if buffer.check(':') and (flow_level or buffer.isBlankZAt(1))
      return _fetch_value()
    end

    /* Is it an alias? */
    if buffer.check('*') then
      return _fetch_anchor(YAML_ALIAS_TOKEN)
    end

    /* Is it an anchor? */
    if buffer.check('&') then
      return _fetch_anchor(YAML_ANCHOR_TOKEN)
    end

    /* Is it a tag? */
    if buffer.check('!') then
      return _fetch_tag()
    end

    /* Is it a literal scalar? */
    if buffer.check('|') and not flow_level then
      return _fetch_block_scalar(1)
    end

    /* Is it a folded scalar? */
    if buffer.check('>') and not flow_level then
      return _fetch_block_scalar(0)
    end

    /* Is it a single-quoted scalar? */
    if buffer.check('\'') then
      return _fetch_flow_scalar(1)
    end

    /* Is it a double-quoted scalar? */
    if buffer.check('"') then
      return _fetch_flow_scalar(0)
    end

    /*
     * Is it a plain scalar?
     *
     * A plain scalar may start with any non-blank characters except
     *
     *      '-', '?', ':', ',', '[', ']', '{', '}',
     *      '#', '&', '*', '!', '|', '>', '\'', '\"',
     *      '%', '@', '`'.
     *
     * In the block context (and, for the '-' indicator, in the flow context
     * too), it may also start with the characters
     *
     *      '-', '?', ':'
     *
     * if it is followed by a non-space character.
     *
     * The last rule is more restrictive than the specification requires.
     */
    if not (buffer.isBlankZ() or buffer.check('-')
                or buffer.check('?') or buffer.check(':')
                or buffer.check(',') or buffer.check('[')
                or buffer.check(']') or buffer.check('{')
                or buffer.check('}') or buffer.check('#')
                or buffer.check('&') or buffer.check('*')
                or buffer.check('!') or buffer.check('|')
                or buffer.check('>') or buffer.check('\'')
                or buffer.check('"') or buffer.check('%')
                or buffer.check('@') or buffer.check('`')) or
            (buffer.check('-') and not buffer.isBlankAt(1)) or
            (not flow_level and
             (buffer.check('?') or buffer.check(':'))
             and not buffer.isBlankZAt(1)) then
      return _fetch_plain_scalar()
    end

    /*
     * If we don't determine the token type so far, it is an error.
     */
    _YamlError("while scanning for the next token", mark,
            "found character that cannot start any token")

  /*
   * Check the list of potential simple keys and remove the positions that
   * cannot contain simple keys anymore.
   */
  fun _stale_simple_keys(): FetchResult =>
    /* Check for a potential simple key for each flow level. */
    for simple_key in simple_keys do
      /*
       * The specification requires that a simple key
       *
       *  - is limited to a single line,
       *  - is shorter than 1024 characters.
       */
      if simple_key.possible
              and (simple_key.mark.line < mark.line
                  or simple_key.mark.index + 1024 < mark.index) then
          /* Check if the potential simple key to be removed is required. */
          if simple_key.required then
              return _YamlError("while scanning a simple key", simple_key.mark,
                      "could not find expected ':'")
          end

          simple_key.possible = false;
      end
    end
    None

  /*
   * Check if a simple key may start at the current position and add it if
   * needed.
   */
  fun _save_simple_key(): FetchResult =>
    /*
     * A simple key is required at the current position if the scanner is in
     * the block context and the current column coincides with the indentation
     * level.
     */
    var required = not flow_level and indent == mark.column

    /*
     * If the current position may start a simple key, save it.
     */
    if simple_key_allowed then
      let simple_key = _YamlSimpleKey.create()
      simple_key.possible = 1
      simple_key.required = required
      simple_key.token_number = tokens_parsed + (tokens.tail - tokens.head)
      simple_key.mark = mark

      let res = _remove_simple_key()
      if not res is None then
        return res
      end

      simple_keys.update(simple_keys.size() - 1, simple_key)
    end
    None

  /*
   * Remove a potential simple key at the current flow level.
   */
  fun _remove_simple_key(): FetchResult =>
    let simple_key = simple_keys.top-1;

    if simple_key.possible then
      /* If the key is required, it is an error. */
      if simple_key.required then
        return _YamlError("while scanning a simple key", simple_key.mark,
                "could not find expected ':'")
      end
    end

    /* Remove the key from the stack. */
    simple_key.possible = false
    None

  /*
   * Increase the flow level and resize the simple key list if needed.
   */
  fun _increase_flow_level() =>
    let empty_simple_key = _YamlSimpleKey.create()
    /* Reset the simple key on the next level. */
    simple_keys.push(empty_simple_key)
    flow_level = flow_level + 1


  /*
   * Decrease the flow level.
   */
  fun _decrease_flow_level() =>
    if flow_level > 0 then
      flow_level = flow_level - 1
      simple_keys.pop()
    end


  /*
   * Push the current indentation level to the stack and set the new level
   * the current column is greater than the indentation level.  In this case,
   * append or insert the specified token into the token queue.
   *
   */
  fun _roll_indent(column U16, number I16, type: TokenType, mark _YamlMark) =>
    /* In the flow context, do nothing. */
    if flow_level > 0 then
      return
    end

    if indent < column then
      /*
       * Push the current indentation level to the stack and set the new
       * indentation level.
       */
      indents.push(indent)
      indent = column
      /* Create a token and insert it into the queue. */
      let token = _YAMLToken(type, mark, mark)
      if number == -1 then
        tokens.enqueue(token)
      else
        tokens.insert(number - tokens_parsed, token)
      end
    end


  /*
   * Pop indentation levels from the indents stack until the current level
   * becomes less or equal to the column.  For each intendation level, append
   * the BLOCK-END token.
   */
  fun _unroll_indent(column: I16) =>
    /* In the flow context, do nothing. */
    if flow_level > 0 then
      return
    end

    /* Loop through the intendation levels in the stack. */
    while indent > column do
      /* Create a token and append it to the queue. */
      let token = _YAMLToken(YAML_BLOCK_END_TOKEN, mark, mark)
      tokens.enqueue(token)
      /* Pop the indentation level. */
      indent = indents.pop()
    end

  /*
   * Initialize the scanner and produce the STREAM-START token.
   */
  fun _fetch_stream_start(): FetchResult =>
    let simple_key = _YamlSimpleKey()
    /* Set the initial indentation. */
    indent = -1
    /* Initialize the simple key stack. */
    simple_keys.push(simple_key)
    /* A simple key is allowed at the beginning of the stream. */
    simple_key_allowed = true
    /* We have started. */
    stream_start_produced = true
    /* Create the STREAM-START token and append it to the queue. */
    let token = _YAMLToken(YAML_STREAM_START_TOKEN, mark, mark, _YamlStreamStartTokenData(encoding))
    tokens.enqueue(token)
    None

  /*
   * Produce the STREAM-END token and shut down the scanner.
   */
  fun _fetch_stream_end(): FetchResult =>
    /* Force new line. */
    if mark.column != 0 then
      mark.column = 0
      mark.line = mark.line + 1
    end

    /* Reset the indentation level. */
    _unroll_indent(-1)

    /* Reset simple keys. */
    res = _remove_simple_key()
    if not res is None then
      return res
    end

    simple_key_allowed = false

    /* Create the STREAM-END token and append it to the queue. */
    let token = _YAMLToken(YAML_STREAM_END_TOKEN, mark, mark)
    tokens.enqueue(token)
    None

  /*
   * Produce a VERSION-DIRECTIVE or TAG-DIRECTIVE token.
   */
  fun _fetch_directive(): FetchResult =>
    /* Reset the indentation level. */
    _unroll_indent(-1)
    /* Reset simple keys. */
    let res = _remove_simple_key()
    if not res is None then
      return res
    end
    simple_key_allowed = false
    /* Create the YAML-DIRECTIVE or TAG-DIRECTIVE token. */
    let res = _scan_directive()
    match res
    | let t: Token => tokens.enqueue(t), None
    else
      res
    end


  /*
   * Produce the DOCUMENT-START or DOCUMENT-END token.
   */
  fun _fetch_document_indicator(tokenType: TokenType): FetchResult =>
    /* Reset the indentation level. */
    _unroll_indent(-1)
    /* Reset simple keys. */
    let res = _remove_simple_key()
    if not res is None then
      return res
    end
    simple_key_allowed = false
    /* Consume the token. */
    let start_mark = mark
    _skip()
    _skip()
    _skip()
    let end_mark = mark
    /* Create the DOCUMENT-START or DOCUMENT-END token. */
    let token = _YAMLToken(tokenType, start_mark, end_mark)
    tokens.enqueue(token)
    None

  /*
   * Produce the FLOW-SEQUENCE-START or FLOW-MAPPING-START token.
   */
  fun _fetch_flow_collection_start(tokenType: TokenType): FetchResult =>
    /* The indicators '[' and '{' may start a simple key. */
    let res = _save_simple_key()
    if not res is None then
      return res
    end

    /* Increase the flow level. */
    _increase_flow_level()

    /* A simple key may follow the indicators '[' and '{'. */
    simple_key_allowed = true

    /* Consume the token. */
    let start_mark = mark
    _skip()
    let end_mark = mark

    /* Create the FLOW-SEQUENCE-START of FLOW-MAPPING-START token. */
    let token = _YAMLToken(tokenType, start_mark, end_mark)
    tokens.enqueue(token)
    None

  /*
   * Produce the FLOW-SEQUENCE-END or FLOW-MAPPING-END token.
   */
  fun _fetch_flow_collection_end(tokenType: TokenType): FetchResult =>
    /* Reset any potential simple key on the current flow level. */
    let res = _remove_simple_key()
    if not res is None then
      return res
    end

    /* Decrease the flow level. */
    _decrease_flow_level()

    /* No simple keys after the indicators ']' and '}'. */
    simple_key_allowed = false

    /* Consume the token. */
    let start_mark = mark
    _skip()
    let end_mark = mark

    /* Create the FLOW-SEQUENCE-END of FLOW-MAPPING-END token. */
    _YAMLToken(tokenType, start_mark, end_mark)
    tokens.enqueue(token)
    None


  /*
   * Produce the FLOW-ENTRY token.
   */
  fun _fetch_flow_entry(): FetchResult =>
    /* Reset any potential simple keys on the current flow level. */
    let res = _remove_simple_key()
    if res is _YamlError then
      return res
    end
    /* Simple keys are allowed after ','. */
    simple_key_allowed = true
    /* Consume the token. */
    let start_mark = mark
    _skip()
    let end_mark = mark
    /* Create the FLOW-ENTRY token and append it to the queue. */
    _YAMLToken(YAML_FLOW_ENTRY_TOKEN, start_mark, end_mark)
    tokens.enqueue(token)
    None

  /*
   * Produce the BLOCK-ENTRY token.
   */
  fun _fetch_block_entry(): FetchResult =>
    /* Check if the scanner is in the block context. */
    if flow_level == 0 then
      /* Check if we are allowed to start a new entry. */
      if not simple_key_allowed then
        return _YamlError(None, mark, "block sequence entries are not allowed in this context");
      end
      /* Add the BLOCK-SEQUENCE-START token if needed. */
      _roll_indent(mark.column, -1, YAML_BLOCK_SEQUENCE_START_TOKEN, mark)
    else
        /*
         * It is an error for the '-' indicator to occur in the flow context,
         * but we let the Parser detect and report about it because the Parser
         * is able to point to the context.
         */
    end
    /* Reset any potential simple keys on the current flow level. */
    let res = _remove_simple_key()
    if not res is None then
      return res
    end
    /* Simple keys are allowed after '-'. */
    simple_key_allowed = true
    /* Consume the token. */
    let start_mark = mark
    _skip()
    let end_mark = mark
    /* Create the BLOCK-ENTRY token and append it to the queue. */
    let token = _YAMLToken(YAML_BLOCK_ENTRY_TOKEN, start_mark, end_mark)
    tokens.enqueue(token)
    None

  /*
   * Produce the KEY token.
   */
  fun _fetch_key(): FetchResult =>
    /* In the block context, additional checks are required. */
    if flow_level == 0 then
      /* Check if we are allowed to start a new key (not nessesary simple). */
      if not simple_key_allowed then
        return _YamlError(None, mark, "mapping keys are not allowed in this context")
      end
      /* Add the BLOCK-MAPPING-START token if needed. */
      _roll_indent(mark.column, -1, YAML_BLOCK_MAPPING_START_TOKEN, mark)
    end
    /* Reset any potential simple keys on the current flow level. */
    let res = _remove_simple_key()
    if not res is None then
      return res
    end
    /* Simple keys are allowed after '?' in the block context. */
    simple_key_allowed = flow_level == 0
    /* Consume the token. */
    let start_mark = mark
    _skip()
    let end_mark = mark
    /* Create the KEY token and append it to the queue. */
    let token = _YAMLToken(YAML_KEY_TOKEN, start_mark, end_mark)
    tokens.enqueue(token)
    None

  /*
   * Produce the VALUE token.
   */
  fun _fetch_value(): FetchResult =>
    let simple_key = simple_keys.top-1
    /* Have we found a simple key? */
    if simple_key.possible then
      /* Create the KEY token and insert it into the queue. */
      let token = _YAMLToken(YAML_KEY_TOKEN, simple_key.mark, simple_key.mark)
      tokens.insert(simple_key.token_number - tokens_parsed, token)
      /* In the block context, we may need to add the BLOCK-MAPPING-START token. */
      _roll_indent(simple_key.mark.column, simple_key.token_number,
                  YAML_BLOCK_MAPPING_START_TOKEN, simple_key.mark)
      /* Remove the simple key. */
      simple_key.possible = false
      /* A simple key cannot follow another simple key. */
      simple_key_allowed = false
    else
      /* The ':' indicator follows a complex key. */
      /* In the block context, extra checks are required. */
      if flow_level == 0 then
        /* Check if we are allowed to start a complex value. */
        if not simple_key_allowed then
          return yaml_parser_set_scanner_error(parser, NULL, mark,
                  "mapping values are not allowed in this context");
        end
        /* Add the BLOCK-MAPPING-START token if needed. */
        _roll_indent(mark.column, -1, YAML_BLOCK_MAPPING_START_TOKEN, mark)
      end
      /* Simple keys after ':' are allowed in the block context. */
      simple_key_allowed = flow_level == 0
    end
    /* Consume the token. */
    let start_mark = mark
    _skip()
    let end_mark = mark
    /* Create the VALUE token and append it to the queue. */
    let token = _YAMLToken(YAML_VALUE_TOKEN, start_mark, end_mark)
    tokens.enqueue(token)
    None

  /*
   * Produce the ALIAS or ANCHOR token.
   */
  fun _fetch_anchor(tokenType: TokenType): FetchResult =>
    /* An anchor or an alias could be a simple key. */
    let res = _save_simple_key()
    if not res is None then
      return res
    end
    /* A simple key cannot follow an anchor or an alias. */
    simple_key_allowed = false
    /* Create the ALIAS or ANCHOR token and append it to the queue. */
    let res = _scan_anchor(tokenType)
    match res
    | let t: Token => tokens.enqueue(token), None
    else
      res
    end

  /*
   * Produce the TAG token.
   */
  fun _fetch_tag(): FetchResult =>
    /* A tag could be a simple key. */
    let res = _save_simple_key()
    if not res is None then
      return res
    end
    /* A simple key cannot follow a tag. */
    simple_key_allowed = false
    /* Create the TAG token and append it to the queue. */
    let res = _scan_tag(tokenType)
    match res
    | let t: Token => tokens.enqueue(token), None
    else
      res
    end

  /*
   * Produce the SCALAR(...,literal) or SCALAR(...,folded) tokens.
   */
  fun _fetch_block_scalar(literal: Bool): FetchResult =>
    /* Remove any potential simple keys. */
    let res = _remove_simple_key()
    if not res is None then
      return res
    end
    /* A simple key may follow a block scalar. */
    simple_key_allowed = true
    /* Create the SCALAR token and append it to the queue. */
    let res = _scan_block_scalar(literal)
    match res
    | let t: Token => tokens.enqueue(token), None
    else
      res
    end

  /*
   * Produce the SCALAR(...,single-quoted) or SCALAR(...,double-quoted) tokens.
   */
  fun _fetch_flow_scalar(single: Bool): FetchResult =>
    /* A plain scalar could be a simple key. */
    let res = _save_simple_key()
    if not res is None then
      return res
    end
    /* A simple key cannot follow a flow scalar. */
    simple_key_allowed = false
    /* Create the SCALAR token and append it to the queue. */
    let res = _scan_flow_scalar(literal)
    match res
    | let t: Token => tokens.enqueue(token), None
    else
      res
    end


  /*
   * Produce the SCALAR(...,plain) token.
   */
  fun _fetch_plain_scalar(): FetchResult =>
    /* A plain scalar could be a simple key. */
    let res = _save_simple_key()
    if not res is None then
      return res
    end
    /* A simple key cannot follow a flow scalar. */
    simple_key_allowed = false
    /* Create the SCALAR token and append it to the queue. */
    let res = _scan_plain_scalar()
    match res
    | let t: Token => tokens.enqueue(token), None
    else
      res
    end

  /*
   * Eat whitespaces and comments until the next token is found.
   */
  fun _scan_to_next_token(): FetchResult
    /* Until the next token is not found. */
    while true do
      /* Allow the BOM mark to start a line. */
      if not buffer.cache(1) then
        return _NeedBytes
      end

      if mark.column == 0 and buffer.isBom() then
        _skip()
      end

      /*
       * Eat whitespaces.
       *
       * Tabs are allowed:
       *
       *  - in the flow context;
       *  - in the block context, but not at the beginning of the line or
       *  after '-', '?', or ':' (complex value).
       */
      if not buffer.cache(1) then
        return _NeedBytes
      end

      while (buffer.check(' ') or
              ((flow_level > 0 or not simple_key_allowed) and
               buffer.check('\t'))) do
        _skip()
        if not buffer.cache(1) then
          return _NeedBytes
        end
      end

      /* Eat a comment until a line break. */
      if buffer.check('#') then
        while not buffer.isBreakZ() do
          _skip()
          if not buffer.cache(1) then
            return _NeedBytes
          end
        end
      end

      /* If it is a line break, eat it. */
      if buffer.isBreak() then
        if not buffer.cache(2) then
          return _NeedBytes
        end
        _skipLine()

        /* In the block context, a new line may start a simple key. */
        if flow_level == 0 then
          simple_key_allowed = true
        end
      else
        /* We have found a token. */
        break
      end
    end
    None


  /*
   * Scan a YAML-DIRECTIVE or TAG-DIRECTIVE token.
   *
   * Scope:
   *      %YAML    1.1    # a commentn
   *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   *      %TAG    !yaml!  tag:yaml.org,2002:n
   *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   */
  fun _scan_directive(): ScanResult =>
    /* Eat '%'. */
    let start_mark = mark
    _skip()

    /* Scan the directive name. */
    let res = _scan_directive_name(start_mark)
    if res is not String then
      return res
    end
    let name = res as String

    let end_mark: _YamlMark

    /* Is it a YAML directive? */
    if name == "YAML" then
      /* Scan the VERSION directive value. */
      let res = _scan_version_directive_value(start_mark)
      if not res is (U16, U16) then
        return res
      end
      let (major: U16, minor: U16) = res as (U16, U16)
      end_mark = mark
      /* Create a VERSION-DIRECTIVE token. */
      token = _YAMLToken(YAML_VERSION_DIRECTIVE_TOKEN, start_mark, end_mark, _YamlVersionDirectiveTokenData(major, minor))
    /* Is it a TAG directive? */
    elseif (strcmp((char *)name, "TAG") == 0) then
      /* Scan the TAG directive value. */
      let res = _scan_tag_directive_value(start_mark)
      if not res is (String, String) then
        return res
      end
      let (handle: String, prefix: String) = res as (String, String)
      end_mark = mark
      /* Create a TAG-DIRECTIVE token. */
      token = _YAMLToken(YAML_TAG_DIRECTIVE_TOKEN, start_mark, end_mark, handle, prefix)
    /* Unknown directive. */
    else
        return _YamlError("while scanning a directive", start_mark, "found uknown directive name")
    end

    /* Eat the rest of the line including any comments. */
    if not buffer.cache(1) then
      return _NeedBytes
    end

    while buffer.isBlank() do
      _skip()
      if not buffer.cache(1) then
        return _NeedBytes
      end
    end

    if buffer.check('#') then
      while not buffer.isBreakZ() do
        _skip()
        if not buffer.cache(1) then
          return _NeedBytes
        end
      end
    end

    /* Check if we are at the end of the line. */
    if not buffer.isBreakZ() then
      return _YamlError("while scanning a directive", start_mark, "did not find expected comment or line break")
    end

    /* Eat a line break. */
    if buffer.isBreak() then
      if not buffer.cache(2)
        return _NeedBytes
      end
      _skipLine()
    end
    None

  /*
   * Scan the directive name.
   *
   * Scope:
   *      %YAML   1.1     # a commentn
   *       ^^^^
   *      %TAG    !yaml!  tag:yaml.org,2002:n
   *       ^^^
   */
  fun _scan_directive_name(start_mark: _YamlMark): (_YamlError | _NeedBytes | String) =>
    /* Consume the directive name. */
    if buffer.cache(1) then
      return _NeedBytes
    end

    let name = String()
    while buffer.isAlpha() do
      name.push(_read())
      if not buffer.cache(1) then
        return _NeedBytes
      end
    end

    /* Check if the name is empty. */
    if name.size() == 0 then
      return _YamlError("while scanning a directive", start_mark, "could not find expected directive name")
    end

    /* Check for an blank character after the name. */
    if not buffer.isBlankZ() then
      return _YamlError("while scanning a directive", start_mark, "found unexpected non-alphabetical character")
    end
    name

  /*
   * Scan the value of VERSION-DIRECTIVE.
   *
   * Scope:
   *      %YAML   1.1     # a commentn
   *           ^^^^^^
   */
  fun _scan_version_directive_value(start_mark: _YamlMark): (_YamlError | _NeedBytes | (U16, U16)) =>
    /* Eat whitespaces. */
    if not buffer.cache(1) then
      return _NeedBytes
    end

    while buffer.isBlank() do
      _skip()
      if not buffer.cache(1) then
        return _NeedBytes
      end
    end

    /* Consume the major version number. */
    let res = _scan_version_directive_number(start_mark)
    if not res is U16 then
      return res
    end
    let major = res as U16

    /* Eat '.'. */
    if not buffer.check('.') then
      return _YamlError("while scanning a %YAML directive", start_mark, "did not find expected digit or '.' character")
    end
    _skip();
    /* Consume the minor version number. */
    let res = _scan_version_directive_number(start_mark)
    if not res is U16 then
      return res
    end
    let minor = res as U16
    (major, minor)

  /*
   * Scan the version number of VERSION-DIRECTIVE.
   *
   * Scope:
   *      %YAML   1.1     # a commentn
   *              ^
   *      %YAML   1.1     # a commentn
   *                ^
   */
  fun _scan_version_directive_number(start_mark: _YamlMark): (_YamlError | _NeedBytes | U16) =>
    var value: U16 = 0
    var length: USize = 0
    /* Repeat while the next character is digit. */
    if not buffer.cache(1) then
      return _NeedBytes
    end
    while buffer.isDigit() do
      /* Check if the number is too long. */
      length = length + 1
      if length > MAX_NUMBER_LENGTH then
        return _YamlError("while scanning a %YAML directive", start_mark, "found extremely long version number")
      }
      value = value * 10 + buffer.asDigit()
      _skip();
      if not buffer.cache(1) then
        return _NeedBytes
      end
    end

    /* Check if the number was present. */
    if length == 0 then
      return _YamlError("while scanning a %YAML directive", start_mark, "did not find expected version number")
    end
    value

  /*
   * Scan the value of a TAG-DIRECTIVE token.
   *
   * Scope:
   *      %TAG    !yaml!  tag:yaml.org,2002:n
   *          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   */
  fun _scan_tag_directive_value(start_mark: _YamlMark): (_YamlError | _NeedBytes | (String, String)) =>
    /* Eat whitespaces. */
    if not buffer.cache(1) then
      return _NeedBytes
    end
    while buffer.isBlank() do
      _skip()
      if not buffer.cache(1) then
        return _NeedBytes
      end
    end

    /* Scan a handle. */
    let res = _scan_tag_handle(1, start_mark)
    if not res is String then
      return res
    end
    let handle_value = res as String

    /* Expect a whitespace. */
    if not buffer.cache(1) then
      return _NeedBytes
    end
    if not buffer.isBlank() then
      return _YamlSimpleKey("while scanning a %TAG directive", start_mark, "did not find expected whitespace")
    end

    /* Eat whitespaces. */
    while buffer.isBlank() do
      _skip()
      if not buffer.cache(1) then
        return _NeedBytes
      end
    end

    /* Scan a prefix. */
    let res = _scan_tag_uri(1, None, start_mark)
    if not res is String then
      return res
    end
    let prefix_value = res as String

    /* Expect a whitespace or line break. */
    if not buffer.cache(1) then
      return _NeedBytes
    end
    if not buffer.isBlankZ() then
      return _YamlError("while scanning a %TAG directive", start_mark, "did not find expected whitespace or line break")
    end
    (handle_value, prefix_value)


  fun _scan_anchor(type: TokenType): (_YamlError | _NeedBytes | Token) =>
    /* Eat the indicator character. */
    let start_mark = mark
    _skip()

    /* Consume the value. */
    if not buffer.cache(1) then
      return _NeedBytes
    end

    let string: String()
    let length: USize = 0
    while buffer.isAlpha() do
      string.push(_read())
      if not buffer.cache(1) then
        return _NeedBytes
      end
      length = length + 1
    end
    end_mark = mark

    /*
     * Check if length of the anchor is greater than 0 and it is followed by
     * a whitespace character or one of the indicators:
     *
     *      '?', ':', ',', ']', '}', '%', '@', '`'.
     */
    if length == 0 or not (buffer.isBlankZ() or buffer.check('?')
                or buffer.check(':') or buffer.check(',')
                or buffer.check(']') or buffer.check('}')
                or buffer.check('%') or buffer.check('@')
                or buffer.check('`')) then
      return _YamlError(if type == YAML_ANCHOR_TOKEN then "while scanning an anchor" else "while scanning an alias" end,
                start_mark, "did not find expected alphabetic or numeric character")
    end

    /* Create a token. */
    if (type == YAML_ANCHOR_TOKEN) {
      _YAMLToken(YAML_ANCHOR_TOKEN, start_mark, end_mark, _YamlAnchorTokenData(string))
    else
      _YAMLToken(YAML_ALIAS_TOKEN, start_mark, end_mark, _YamlAliasTokenData(string))
    end

  /*
   * Scan a TAG token.
   */
  fun _scan_tag(): (_YamlError | _NeedBytes | Token) =>
    let start_mark = mark

    /* Check if the tag is in the canonical form. */
    if not buffer.cache(2) then
      return _NeedBytes
    end
    let handle: String
    let suffix: String
    if buffer.checkAt('<', 1) then
      /* Set the handle to '' */
      handle = String(1)
      handle.push('\0')
      /* Eat '!<' */
      _skip()
      _skip()
      /* Consume the tag value. */
      let res = _scan_tag_uri(0, None, start_mark)
      if not res is String then
        return res
      end
      let suffix = res as String
      /* Check for '>' and eat it. */
      if not buffer.check('>') then
        return _YamlError("while scanning a tag", start_mark, "did not find the expected '>'")
      end
      _skip()
    else
      /* The tag has either the '!suffix' or the '!handle!suffix' form. */
      /* First, try to scan a handle. */
      let res = _scan_tag_handle(0, start_mark)
      if not res is String then
        return res
      end
      handle = res as String

      /* Check if it is, indeed, handle. */
      if handle.at(0) == '!' and handle.at(1) != '\0' and handle.at(handle.size() - 1) == '!' then
        /* Scan the suffix now. */
        let res = _scan_tag_uri(0, None, start_mark)
        if not res is String then
          return res
        end
        let suffix = res as String
      else
        /* It wasn't a handle after all.  Scan the rest of the tag. */
        let res = _scan_tag_uri(0, None, start_mark)
        if not res is String then
          return res
        end
        let suffix = res as String
        /* Set the handle to '!'. */
        handle.reset()
        handle.push('!')
        handle.push('\0')
        /*
         * A special case: the '!' tag.  Set the handle to '' and the
         * suffix to '!'.
         */
        if suffix.at(0) == '\0' then
          suffix = handle = suffix
        end
      end
    end

    /* Check the character which ends the tag. */
    if not buffer.cache(1) then
      return _NeedBytes
    end

    if not buffer.isBlankZ() then
      return _YamlError("while scanning a tag", start_mark, "did not find expected whitespace or line break")
    end
    let end_mark = mark;
    _YAMLToken(YAML_TAG_TOKEN, start_mark, end_mark, _YamlTagTokenData(handle, suffix))

  /*
   * Scan a tag handle.
   */
  fun _scan_tag_handle(directive: Bool, start_mark: _YamlMark): (_YamlError | _NeedBytes | String) =>
    /* Check the initial '!' character. */
    if not buffer.cache(1) then
      return _NeedBytes
    end
    if not buffer.check('!') then
      return _YamlError(if directive then "while scanning a tag directive" else "while scanning a tag" end,
                start_mark, "did not find expected '!'")
    end

    /* Copy the '!' character. */
    let handle = String()
    handle.push(_read())

    /* Copy all subsequent alphabetical and numerical characters. */
    if not buffer.cache(1) then
      return _NeedBytes
    end
    while buffer.isAlpha() do
      handle.push(_read())
      if not buffer.cache(1) then
        return _NeedBytes
      end
    end

    /* Check if the trailing character is '!' and copy it. */
    if buffer.check('!') then
      handle.push(_read())
    else
      /*
       * It's either the '!' tag or not really a tag handle.  If it's a %TAG
       * directive, it's an error.  If it's a tag token, it must be a part of
       * URI.
       */

      if (directive and not (string.at(0) == '!' and string.at(1) == '\0')) then
        return _YamlError("while parsing a tag directive", start_mark, "did not find expected '!'")
      end
    end
    handle

  /*
   * Scan a tag.
   */
  fun _scan_tag_uri(directive: Bool, head: (String | None), start_mark: _YamlMark): (_YamlError | _NeedBytes | String) =>
    let uri: String = match head
                      | let s: String => s.clonse()
                      else String()
                      end

    /* Scan the tag. */
    if not buffer.cache(1) then
      return _NeedBytes
    end

    /*
     * The set of characters that may appear in URI is as follows:
     *
     *      '0'-'9', 'A'-'Z', 'a'-'z', '_', '-', ';', '/', '?', ':', '@', '&',
     *      '=', '+', '$', ',', '.', '!', '~', '*', '\'', '(', ')', '[', ']',
     *      '%'.
     */
    while buffer.isAlpha() or buffer.check(';') do
            or buffer.check('/') or buffer.check('?')
            or buffer.check(':') or buffer.check('@')
            or buffer.check('&') or buffer.check('=')
            or buffer.check('+') or buffer.check('$')
            or buffer.check(',') or buffer.check('.')
            or buffer.check('!') or buffer.check('~')
            or buffer.check('*') or buffer.check('\'')
            or buffer.check('(') or buffer.check(')')
            or buffer.check('[') or buffer.check(']')
            or buffer.check('%') do
      /* Check if it is a URI-escape sequence. */
      if buffer.check('%') then
        let res = _scan_uri_escapes(directive, start_mark, &string)
        if not res is String then
          return res
        end
        uri.append(res as String)
      else
        uri.push(_read())
      end

      if not buffer.cache(1) then
        return _NeedBytes
      end
    end

    /* Check if the tag is non-empty. */
    if uri.size() == 0 then
      return _YamlError(if directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                start_mark, "did not find expected tag URI")
    end
    uri

  /*
   * Decode an URI-escape sequence corresponding to a single UTF-8 character.
   */
  fun _scan_uri_escapes(directive: Bool, start_mark: _YamlMark): (_YamlError | _NeedBytes | String) =>
    var width: USize = 0
    let string = String()
    /* Decode the required number of characters. */
    do
      /* Check for a URI-escaped octet. */
      if not buffer.cache(3) then
        return _NeedBytes
      end

      if not (buffer.check('%') and buffer.isHexAt(1) and buffer.isHexAt(2)) then
        return _YamlError(if directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  start_mark, "did not find URI escaped octet")
      end

      /* Get the octet. */
      let octet: U8 = (buffer.asHexAt(1) << 4) + buffer.asHexAt(2)

      /* If it is the leading octet, determine the length of the UTF-8 sequence. */
      if width == 0 then
        width = (octet & 0x80) == 0x00 ? 1 :
                (octet & 0xE0) == 0xC0 ? 2 :
                (octet & 0xF0) == 0xE0 ? 3 :
                (octet & 0xF8) == 0xF0 ? 4 : 0;
        if width == 0 then
          return _YamlError(if directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  start_mark, "found an incorrect leading UTF-8 octet")
        end
      else
        /* Check if the trailing octet is correct. */
        if ((octet & 0xC0) != 0x80) then
          return _YamlError(if directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  start_mark, "found an incorrect trailing UTF-8 octet")
        end
      end

      /* Copy the octet and move the pointers. */
      string.push(octet)
      _skip()
      _skip()
      _skip()
      width = width - 1
    } while (width > 0)
    string


  /*
   * Scan a block scalar.
   */
  fun _scan_block_scalar(literal: Bool): (_YamlError | _NeedBytes | Token) =>
    /* Eat the indicator '|' or '>'. */
    let start_mark = mark
    _skip()

    /* Scan the additional block scalar indicators. */
    if not buffer.cache(1) then
      return _NeedBytes
    end

    var chomping: I8 = 0
    var increment: U8 = 0

    /* Check for a chomping indicator. */
    if buffer.check('+') or buffer.check('-') then
      /* Set the chomping method and eat the indicator. */
      chomping = if buffer.check('+') then +1 else -1 end
      _skip()

      /* Check for an indentation indicator. */
      if not buffer.cache(1) then
        return _NeedBytes
      end

      if buffer.isDigit() then
        /* Check that the intendation is greater than 0. */
        if buffer.check('0') then
          return _YamlError("while scanning a block scalar", start_mark, "found an intendation indicator equal to 0")
        end
        /* Get the intendation level and eat the indicator. */
        increment = buffer.asDigit()
        _skip()
      end

    /* Do the same as above, but in the opposite order. */
    elseif buffer.isDigit() then
      if buffer.check('0') then
        return _YamlError("while scanning a block scalar", start_mark, "found an intendation indicator equal to 0")
      end
      increment = buffer.asDigit()
      _skip()
      if not buffer.cache(1) then
        return _NeedBytes
      end
      if buffer.check('+') or buffer.check('-') then
        chomping = if buffer.check('+') then +1 else -1 end
        _skip()
      end
    end

    /* Eat whitespaces and comments to the end of the line. */
    if not buffer.cache(1) then
      return _NeedBytes
    end
    while buffer.isBlank() do
      _skip()
      if not buffer.cache(1) then
        return _NeedBytes
      end
    end
    if buffer.check('#') then
      while not buffer.isBreakZ() do
        _skip()
        if not buffer.cache(1) then
          return _NeedBytes
        end
      end
    end

    /* Check if we are at the end of the line. */
    if not buffer.isBreakZ() then
      return _YamlError("while scanning a block scalar", start_mark, "did not find expected comment or line break")
    end

    /* Eat a line break. */
    if buffer.isBreak() then
      if not buffer.cache(2) then
        return _NeedBytes
      end
      _skipLine()
    end

    let end_mark = mark

    var indent: U16 = 0
    /* Set the intendation level if it was specified. */
    if increment > 0 then
      indent = if this.indent >= 0 then this.indent + increment else increment end
    end

    /* Scan the leading line breaks and determine the indentation level if needed. */
    let res = _scan_block_scalar_breaks(indent, start_mark)
    if not res is (U16, String, _YamlMark) then
      return res
    end
    indent, trailing_breaks, end_mark = res as (U16, String, _YamlMark)

    /* Scan the block scalar content. */
    var trailing_blank: Bool = false
    var leading_blank: Bool = false
    if not buffer.cache(1) then
      return _NeedBytes
    end
    while (mark.column == indent and not buffer.isZ()) do
      /*
       * We are at the beginning of a non-empty line.
       */

      /* Is it a trailing whitespace? */
      trailing_blank = buffer.isBlank()

      /* Check if we need to fold the leading line break. */
      if (not literal and leading_break.at(0) == '\n' and not leading_blank and not trailing_blank) then
          /* Do we need to join the lines by space? */
          if trailing_breaks.at(0) == '\0' then
            string.push(' ')
          end
          leading_break.clear()
      else
        string.append(leading_break)
        leading_break.clear()
      end

      /* Append the remaining line breaks. */
      string.append(trailing_breaks)
      trailing_breaks.clear()

      /* Is it a leading whitespace? */
      leading_blank = buffer.isBlank()

      /* Consume the current line. */
      while not buffer.isBreakZ() do
        string.push(_read())
        if not buffer.cache(1) then
          return _NeedBytes
        end
      end

      /* Consume the line break. */
      if not buffer.cache(2) then
        return _NeedBytes
      end

      _readLine(leading_break)

      /* Eat the following intendation spaces and line breaks. */
      let res = _scan_block_scalar_breaks(indent, start_mark)
      if not res is (U16, String, _YamlMark) then
        return res
      end
      indent, trailing_breaks, end_mark = res as (U16, String, _YamlMark)
    end

    /* Chomp the tail. */
    if chomping != -1 then
      string.append(leading_break)
    end
    if chomping == 1 then
      string.append(trailing_breaks)
    end

    /* Create a token. */
    _YAMLToken(YAML_SCALAR_TOKEN, start_mark, end_mark,
      _YamlScalarTokenData(string, if literal then YAML_LITERAL_SCALAR_STYLE else YAML_FOLDED_SCALAR_STYLE end))


  /*
   * Scan intendation spaces and line breaks for a block scalar.  Determine the
   * intendation level if needed.
   */
  fun _scan_block_scalar_breaks(indent: U16, start_mark _YamlMark): (_YamlError | _NeedBytes | (U16, String, _YamlMark))
    var max_indent: U16 = 0
    var end_mark = mark
    var breaks: String

    /* Eat the intendation spaces and line breaks. */
    while true do
      /* Eat the intendation spaces. */
      if not buffer.cache(1) then
        return _NeedBytes
      end

      while ((indent == 0 or mark.column < indent) and buffer.isSpace()) do
        _skip()
        if not buffer.cache(1) then
          return _NeedBytes
        end
      end

      if mark.column > max_indent then
        max_indent = mark.column
      end

      /* Check for a tab character messing the intendation. */
      if ((indent == 0 or mark.column < indent) and buffer.isTab()) then
          return _YamlError("while scanning a block scalar",
             start_mark, "found a tab character where an intendation space is expected")
      end

      /* Have we found a non-empty line? */
      if not buffer.isBreak() then
        break
      end

      /* Consume the line break. */
      if not buffer.cache(2) then
        return _NeedBytes
      end
      _readLine(breaks)
      end_mark = mark
    end

    /* Determine the indentation level if needed. */
    if (indent == 0) then
      indent = max_indent
      if indent < indent + 1 then
        indent = indent + 1
      end
      if indent < 1 then
        indent = 1
      end
    end

    (indent, breaks, end_mark)


  /*
   * Scan a quoted scalar.
   */
  fun _scan_flow_scalar(single: Bool): (_YamlError | _NeedBytes | Token) =>
    /* Eat the left quote. */
    start_mark = mark
    _skip()

    /* Consume the content of the quoted scalar. */
    while true do
      /* Check that there are no document indicators at the beginning of the line. */
      if not buffer.cache(4) then
        return _NeedBytes
      end

      if (mark.column == 0 and
          ((buffer.checkAt('-', 0) and
            buffer.checkAt('-', 1) and
            buffer.checkAt('-', 2)) or
           (buffer.checkAt('.', 0) and
            buffer.checkAt('.', 1) and
            buffer.checkAt('.', 2))) and
          buffer.isBlankZAt(3)) then
        return _YamlError("while scanning a quoted scalar", start_mark, "found unexpected document indicator")
      end

      /* Check for EOF. */
      if (buffer.isZ()) then
        return _YamlError("while scanning a quoted scalar", start_mark, "found unexpected end of stream")
      end

      /* Consume non-blank characters. */
      if not buffer.cache(2) then
        return _NeedBytes
      end
      leading_blanks = 0

      while not buffer.isBlankZ() do
        /* Check for an escaped single quote. */
        if (single and buffer.checkAt('\'', 0) and buffer.checkAt('\'', 1)) then
          string.push('\'')
          _skip()
          _skip()
        /* Check for the right quote. */
        else if (buffer.check(single ? '\'' : '"')) then
          break
        /* Check for an escaped line break. */
        else if (!single and buffer.check('\\') and buffer.isBreakAt(1)) then
          if not buffer.cache(3) then
            return _NeedBytes
          end
          _skip()
          _skipLine()
          leading_blanks = 1
          break
        /* Check for an escape sequence. */
        else if (not single and buffer.check('\\')) then
          var code_length : USize = 0
          /* Check the escape character. */
          match buffer.at(1)
          | '0' => string.push('\0')
          | 'a' => string.push('\x07')
          | 'b' => string.push('\x08')
          | 't' or '\t' => string.push('\x09')
          | 'n' => string.push('\x0A')
          | 'v' => string.push('\x0B')
          | 'f' => string.push('\x0C')
          | 'r' => string.push('\x0D')
          | 'e' => string.push('\x1B')
          | ' ' => string.push('\x20')
          | '"' => string.push('"')
          | '\'' => string.push('\'')
          | '\\' => string.push('\\')
          | 'N' => string.push('\xC2'), string.push('\x85')   /* NEL (#x85) */
          | '_' => string.push('\xC2'), string.push('\xA0')   /* #xA0 */
          | 'L' => string.push('\xE2'), string.push('\x80'), string.push('\xA8')   /* LS (#x2028) */
          | 'P' => string.push('\xE2'), string.push('\x80'), string.push('\xA9')   /* PS (#x2029) */
          | 'x' => code_length = 2
          | 'u' => code_length = 4
          | 'U' => code_length = 8
          else
            return _YamlError("while parsing a quoted scalar", start_mark, "found unknown escape character")
          end
          _skip()
          _skip()

          /* Consume an arbitrary escape code. */
          if (code_length > 0) then
            /* Scan the character value. */
            if buffer.cache(code_length) then
              return _NeedBytes
            end
            var value: U32 = 0
            for k in Range(0, code_length) do
              if not buffer.isHexAt(k) then
                return _YamlError("while parsing a quoted scalar",
                          start_mark, "did not find expected hexdecimal number")
              end
              value = (value << 4) + buffer.asHexAt(k)
            end

            /* Check the value and write the character. */
            if ((value >= 0xD800 and value <= 0xDFFF) or value > 0x10FFFF) then
              return _YamlError("while parsing a quoted scalar",
                        start_mark, "found invalid Unicode character escape code")
            end

            if (value <= 0x7F) then
              string.push(value)
            elseif (value <= 0x7FF) then
              string.push(0xC0 + (value >> 6))
              string.push(0x80 + (value & 0x3F))
            elseif (value <= 0xFFFF) then
              string.push(0xE0 + (value >> 12))
              string.push(0x80 + ((value >> 6) & 0x3F))
              string.push(0x80 + (value & 0x3F))
            else
              string.push(0xF0 + (value >> 18))
              string.push(0x80 + ((value >> 12) & 0x3F))
              string.push(0x80 + ((value >> 6) & 0x3F))
              string.push(0x80 + (value & 0x3F))
            end

            /* Advance the pointer. */
            for k in Range(0, code_length) do
              _skip()
            end
          end
        else
          /* It is a non-escaped non-blank character. */
          string.push(_read())
        end

        if not buffer.cache(2) then
          return _NeedBytes
        end
      end

      /* Check if we are at the end of the scalar. */
      if (buffer.check(if single then '\'' else '"' end)) then
        break
      end

      /* Consume blank characters. */
      if not buffer.cache(1) then
        return _NeedBytes
      end

      while (buffer.isBlank() or buffer.isBreak()) do
        if (buffer.isBlank()) then
          /* Consume a space or a tab character. */
          if (not leading_blanks) then
            whitespaces.push(_read())
          else
            _skip()
          end
        else
          if not buffer.cache(2) then
            return _NeedBytes
          end

          /* Check if it is a first line break. */
          if not leading_blanks then
            whitespaces.clear()
            _readLine(leading_break)
            leading_blanks = true
          else
            _readLine(trailing_breaks)
          end
        end
        if not buffer.cache(1) then
          return _NeedBytes
        end
      end

      /* Join the whitespaces or fold line breaks. */
      if (leading_blanks) then
        /* Do we need to fold line breaks? */
        if (leading_break.at(0) == '\n') then
          if (trailing_breaks.at(0) == '\0') then
            string.push(' ')
          else
            string.append(trailing_breaks)
            trailing_breaks.clear()
          end
          leading_break.clear()
        else
          string.append(leading_break)
          string.append(trailing_breaks)
          leading_break.clear()
          trailing_breaks.clear()
        end
      else
        string.append(whitespaces)
        whitespaces.clear()
      end
    end

    /* Eat the right quote. */
    _skip()
    end_mark = mark
    /* Create a token. */
    _YAMLToken(YAML_SCALAR_TOKEN, start_mark, end_mark,
      _YamlScalarTokenData(string, single ? YAML_SINGLE_QUOTED_SCALAR_STYLE : YAML_DOUBLE_QUOTED_SCALAR_STYLE))


  /*
   * Scan a plain scalar.
   */
  fun _scan_plain_scalar(): (_YamlError | _NeedBytes | Token) =>
    yaml_mark_t start_mark;
    yaml_mark_t end_mark;
    yaml_string_t string = NULL_STRING;
    yaml_string_t leading_break = NULL_STRING;
    yaml_string_t trailing_breaks = NULL_STRING;
    yaml_string_t whitespaces = NULL_STRING;
    int leading_blanks = 0;
    int indent = indent+1;

    if (!STRING_INIT(parser, string, INITIAL_STRING_SIZE)) goto error;
    if (!STRING_INIT(parser, leading_break, INITIAL_STRING_SIZE)) goto error;
    if (!STRING_INIT(parser, trailing_breaks, INITIAL_STRING_SIZE)) goto error;
    if (!STRING_INIT(parser, whitespaces, INITIAL_STRING_SIZE)) goto error;

    end_mark = mark
    start_mark = mark

    /* Consume the content of the plain scalar. */
    while true do
      /* Check for a document indicator. */
      if not buffer.cache(4) then
        return _NeedBytes
      end

      if (mark.column == 0 and
          ((buffer.checkAt('-', 0) and
            buffer.checkAt('-', 1) and
            buffer.checkAt('-', 2)) or
           (buffer.checkAt('.', 0) and
            buffer.checkAt('.', 1) and
            buffer.checkAt('.', 2))) and
          buffer.isBlankZAt(3)) then
        break
      end

      /* Check for a comment. */
      if (buffer.check('#')) then
        break
      end

      /* Consume non-blank characters. */
      while (!buffer.isBlankZ()) do
        /* Check for 'x:x' in the flow context. TODO: Fix the test "spec-08-13". */
        if (flow_level > 0 and buffer.check(':') and not buffer.isBlankZAt(1)) end
          return _YamlError("while scanning a plain scalar", start_mark, "found unexpected ':'")
        end

        /* Check for indicators that may end a plain scalar. */
        if ((buffer.check(':') and buffer.isBlankZAt(1))
                or (flow_level and
                    (buffer.check(',') or buffer.check(':')
                     or buffer.check('?') or buffer.check('[')
                     or buffer.check(']') or buffer.check('{')
                     or buffer.check('}')))) then
          break
        end

        /* Check if we need to join whitespaces and breaks. */
        if (leading_blanks or whitespaces.size() > 0) then
          if (leading_blanks) then
            /* Do we need to fold line breaks? */
            if (leading_break.at(0) == '\n') then
              if (trailing_breaks.at(0) == '\0') then
                string.append(' ')
              else
                string.append(trailing_breaks)
                trailing_breaks.clear()
              end
              leading_break.clear()
            else
              string.append(leading_break)
              string.append(trailing_breaks)
              leading_break.clear()
              trailing_breaks.clear()
            end
            leading_blanks = false
          else
            string.append(whitespaces)
            whitespaces.clear()
          end
        end

        /* Copy the character. */
        string.push(_read())
        end_mark = mark
        if not buffer.cache(2) then
          return _NeedBytes
        end
      end

      /* Is it the end? */
      if (not (buffer.isBlank() or buffer.isBreak())) then
        break
      end

      /* Consume blank characters. */
      if not buffer.cache(1) then
        return _NeedBytes
      end

      while (buffer.isBlank() or buffer.isBreak()) do
        if (buffer.isBlank()) then
          /* Check for tab character that abuse intendation. */
          if (leading_blanks and mark.column < indent and buffer.isTab()) then
            return _YamlError("while scanning a plain scalar",
               start_mark, "found a tab character that violate intendation")
          end

          /* Consume a space or a tab character. */
          if (not leading_blanks) then
            whitespaces.push(_read())
          else
            _skip()
          end
        else
          if not buffer.cache(2) then
            return _NeedBytes
          end

          /* Check if it is a first line break. */
          if (not leading_blanks) then
            whitespaces.clear()
            _readLine(leading_break)
            leading_blanks = true
          else
            _readLine(trailing_breaks)
          end
        end
        if not buffer.cache(1) then
          return _NeedBytes
        end
      end

      /* Check intendation level. */

      if (flow_level == 0 and mark.column < indent) then
        break
      end
    end

    /* Create a token. */
    let token = _YAMLToken(YAML_SCALAR_TOKEN, start_mark, end_mark, _YamlScalarTokenData(string, YAML_PLAIN_SCALAR_STYLE))

    /* Note that we change the 'simple_key_allowed' flag. */
    if (leading_blanks) then
      simple_key_allowed = true
    end

    token
