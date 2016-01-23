
primitive _BlockIn
primitive _BlockOut
primitive _FlowOut
primitive _BlockKey

type _ParseContext is (_BlockIn | _BlockOut | _FlowOut, _BlockKey)

interface InputStream
  fun ref read(len: USize): Array[U8] iso^ =>
    None

let BUFFER_SIZE: USize val = 1024

class _Parser

  let h: YamlHandler
  let input: InputStream
  var buffer: Array[U8] = None
  var pos: ISize = 0

  new create(h': YamlHandler, input': InputStream) =>
    h = h'
    intput = input'

  fun _ensureBufferFilled() =>
    if buffer == None or pos == buffer.size() then
      buffer = input.read(BUFFER_SIZE)
    end

  fun chars(s: String) =>
    reader.mark()
    for c in s do
      if c != reader.nextChar() then
        reader.reset()
        return false
      end
    end
    return true

  // [1] c-printable ::= #x9 | #xA | #xD | [#x20-#x7E] /* 8 bit */ | #x85 | [#xA0-#xD7FF] | [#xE000-#xFFFD] /* 16 bit */ | [#x10000-#x10FFFF] /* 32 bit */
  fun c_printable() =>
    read(#x9)
    // TODO

  // [2] nb-json ::= #x9 | [#x20-#x10FFFF]
  fun nb_json() =>

  // [3] c-byte-order-mark ::= #xFEFF
  fun c_byte_order_mark() =>

  // [4]c-sequence-entry::= “-”
  fun c_sequence_entry() =>
    chars("-")

  // [5]c-mapping-key::= “?”
  fun c_mapping_key() =>
    chars("?")

  // [6]c-mapping-value::= “:”
  fun c_mapping_value() =>
    chars(":")

  // [7]c-collect-entry::= “,”
  fun c_collect_entry() =>
    chars(",")

  // [8]c-sequence-start::= “[”
  fun c_sequence_start() =>
    chars("[")

  // [9]c-sequence-end::= “]”
  fun c_sequence_end() =>
    chars("]")

  // [10]c-mapping-start::= “{”
  fun c_mapping_start() =>
    chars("{")

  // [11]c-mapping-end::= “}”
  fun c_mapping_end() =>
    chars("}")

  // [12]c-comment::= “#”
  fun c_comment() =>
    chars("#")

  // [13]c-anchor::= “&”
  fun c_anchor() =>
    read("&")

  // [14]c-alias::= “*”
  fun c_alias() =>
    chars("*")

  // [15]c-tag::= “!”
  fun c_tag() =>
    chars("!")

  // [16]c-literal::= “|”
  fun c_literal() =>
    chars("|")

  // [17]c-folded::= “>”
  fun c_folded() =>
    chars(">")

  // [18]c-single-quote::= “'”
  fun c_single_quote() =>
    chars("\'")

  // [19]c-double-quote::= “"”
  fun c_double_quote() =>
    chars("\"")

  // [20]c-directive::= “%”
  fun c_directive() =>
    chars("%")

  // [21]c-reserved::= “@” | “`”
  fun c_directive() =>
    chars("@")
    chars("`")

  // [22] c-indicator ::= “-” | “?” | “:” | “,” | “[” | “]” | “{” | “}” | “#” | “&” | “*” | “!” | “|” | “>” | “'” | “"” | “%” | “@” | “`”
  fun c_indicator() =>
    chars("-")
    char("?")
    char(":")
    char(",")
    char("[")
    char("]")
    char("{")
    char("}")
    char("#")
    char("&")
    char("*")
    char("!")
    char("|")
    char(">")
    char("\'")
    char("\"")
    char("%")
    char("@")
    char("`")

  // [23] c-flow-indicator ::= “,” | “[” | “]” | “{” | “}”
  // [24] b-line-feed ::= #xA /* LF */
  // [25] b-carriage-return ::= #xD /* CR */
  // [26] b-char ::= b-line-feed | b-carriage-return
  // [27] nb-char ::= c-printable - b-char - c-byte-order-mark
  // [28] b-break ::= ( b-carriage-return b-line-feed ) /* DOS, Windows */ | b-carriage-return /* MacOS upto 9.x */ | b-line-feed /* UNIX, MacOS X */
  // [29] b-as-line-feed ::= b-break
  // [30] b-non-content ::= b-break
  // [31] s-space ::= #x20 /* SP */
  // [32] s-tab ::= #x9 /* TAB */
  // [33] s-white ::= s-space | s-tab
  // [34] ns-char ::= nb-char - s-white
  // [35] ns-dec-digit ::= [#x30-#x39] /* 0-9 */
  // [36] ns-hex-digit ::= ns-dec-digit | [#x41-#x46] /* A-F */ | [#x61-#x66] /* a-f */
  // [37] ns-ascii-letter ::= [#x41-#x5A] /* A-Z */ | [#x61-#x7A] /* a-z */
  // [38] ns-word-char ::= ns-dec-digit | ns-ascii-letter | “-”
  // [39] ns-uri-char ::= “%” ns-hex-digit ns-hex-digit | ns-word-char | “#” | “;” | “/” | “?” | “:” | “@” | “&” | “=” | “+” | “$” | “,” | “_” | “.” | “!” | “~” | “*” | “'” | “(” | “)” | “[” | “]”
  // [40] ns-tag-char ::= ns-uri-char - “!” - c-flow-indicator
  // [41] c-escape ::= “\”
  // [42]ns-esc-null::= “0”
  // [43]ns-esc-bell::= “a”
  // [44]ns-esc-backspace::= “b”
  // [45]ns-esc-horizontal-tab::= “t” | #x9
  // [46]ns-esc-line-feed::= “n”
  // [47]ns-esc-vertical-tab::= “v”
  // [48]ns-esc-form-feed::= “f”
  // [49]ns-esc-carriage-return::= “r”
  // [50]ns-esc-escape::= “e”
  // [51]ns-esc-space::= #x20
  // [52]ns-esc-double-quote::= “"”
  // [53]ns-esc-slash::= “/”
  // [54]ns-esc-backslash::= “\”
  // [55]ns-esc-next-line::= “N”
  // [56]ns-esc-non-breaking-space::= “_”
  // [57]ns-esc-line-separator::= “L”
  // [58]ns-esc-paragraph-separator::= “P”
  // [59]ns-esc-8-bit::= “x” ( ns-hex-digit × 2 )
  // [60]ns-esc-16-bit::= “u” ( ns-hex-digit × 4 )
  // [61]ns-esc-32-bit::= “U” ( ns-hex-digit × 8 )
  // [62] c-ns-esc-char ::= “\” ( ns-esc-null | ns-esc-bell | ns-esc-backspace | ns-esc-horizontal-tab | ns-esc-line-feed | ns-esc-vertical-tab | ns-esc-form-feed | ns-esc-carriage-return | ns-esc-escape | ns-esc-space | ns-esc-double-quote | ns-esc-slash | ns-esc-backslash | ns-esc-next-line | ns-esc-non-breaking-space | ns-esc-line-separator | ns-esc-paragraph-separator | ns-esc-8-bit | ns-esc-16-bit | ns-esc-32-bit )
  // [63] s-indent(n) ::= s-space × n
  // [64] s-indent(<n) ::= s-space × m /* Where m < n */
  // [65] s-indent(≤n) ::= s-space × m /* Where m ≤ n */
  // [66] s-separate-in-line ::= s-white+ | /* Start of line */
  // [67] s-line-prefix(n,c) ::= c = block-out ⇒ s-block-line-prefix(n) c = block-in ⇒ s-block-line-prefix(n) c = flow-out ⇒ s-flow-line-prefix(n) c = flow-in ⇒ s-flow-line-prefix(n)
  // [68] s-block-line-prefix(n) ::= s-indent(n)
  // [69] s-flow-line-prefix(n) ::= s-indent(n) s-separate-in-line?
  // [70] l-empty(n,c) ::= ( s-line-prefix(n,c) | s-indent(<n) ) b-as-line-feed
  // [71] b-l-trimmed(n,c) ::= b-non-content l-empty(n,c)+
  // [72] b-as-space ::= b-break
  // [73] b-l-folded(n,c) ::= b-l-trimmed(n,c) | b-as-space
  // [74] s-flow-folded(n) ::= s-separate-in-line? b-l-folded(n,flow-in) s-flow-line-prefix(n)
  // [75] c-nb-comment-text ::= “#” nb-char*
  // [76] b-comment ::= b-non-content | /* End of file */
  // [77] s-b-comment ::= ( s-separate-in-line c-nb-comment-text? )? b-comment
  // [78] l-comment ::= s-separate-in-line c-nb-comment-text? b-comment
  // [79] s-l-comments ::= ( s-b-comment | /* Start of line */ ) l-comment*
  // [80] s-separate(n,c) ::= c = block-out ⇒ s-separate-lines(n) c = block-in ⇒ s-separate-lines(n) c = flow-out ⇒ s-separate-lines(n) c = flow-in ⇒ s-separate-lines(n) c = block-key ⇒ s-separate-in-line c = flow-key ⇒ s-separate-in-line
  // [81] s-separate-lines(n) ::= ( s-l-comments s-flow-line-prefix(n) ) | s-separate-in-line
  // [82] l-directive ::= “%” ( ns-yaml-directive | ns-tag-directive | ns-reserved-directive ) s-l-comments
  // [83] ns-reserved-directive ::= ns-directive-name ( s-separate-in-line ns-directive-parameter )*
  // [84] ns-directive-name ::= ns-char+
  // [85] ns-directive-parameter ::= ns-char+
  // [86] ns-yaml-directive ::= “Y” “A” “M” “L” s-separate-in-line ns-yaml-version
  // [87] ns-yaml-version ::= ns-dec-digit+ “.” ns-dec-digit+
  // [88] ns-tag-directive ::= “T” “A” “G” s-separate-in-line c-tag-handle s-separate-in-line ns-tag-prefix
  // [89] c-tag-handle ::= c-named-tag-handle | c-secondary-tag-handle | c-primary-tag-handle
  // [90] c-primary-tag-handle ::= “!”
  // [91] c-secondary-tag-handle ::= “!” “!”
  // [92] c-named-tag-handle ::= “!” ns-word-char+ “!”
  // [93] ns-tag-prefix ::= c-ns-local-tag-prefix | ns-global-tag-prefix
  // [94] c-ns-local-tag-prefix ::= “!” ns-uri-char*
  // [95] ns-global-tag-prefix ::= ns-tag-char ns-uri-char*
  // [96] c-ns-properties(n,c) ::= ( c-ns-tag-property ( s-separate(n,c) c-ns-anchor-property )? ) | ( c-ns-anchor-property ( s-separate(n,c) c-ns-tag-property )? )
  // [97] c-ns-tag-property ::= c-verbatim-tag | c-ns-shorthand-tag | c-non-specific-tag
  // [98] c-verbatim-tag ::= “!” “<” ns-uri-char+ “>”
  // [99] c-ns-shorthand-tag ::= c-tag-handle ns-tag-char+
  // [100] c-non-specific-tag ::= “!”
  // [101] c-ns-anchor-property ::= “&” ns-anchor-name
  // [102] ns-anchor-char ::= ns-char - c-flow-indicator
  // [103] ns-anchor-name ::= ns-anchor-char+
  // [104] c-ns-alias-node ::= “*” ns-anchor-name
  // [105] e-scalar ::= /* Empty */
  // [106] e-node ::= e-scalar
  // [107] nb-double-char ::= c-ns-esc-char | ( nb-json - “\” - “"” )
  // [108] ns-double-char ::= nb-double-char - s-white
  // [109] c-double-quoted(n,c) ::= “"” nb-double-text(n,c) “"”
  // [110] nb-double-text(n,c) ::= c = flow-out ⇒ nb-double-multi-line(n) c = flow-in ⇒ nb-double-multi-line(n) c = block-key ⇒ nb-double-one-line c = flow-key ⇒ nb-double-one-line
  // [111] nb-double-one-line ::= nb-double-char*
  // [112] s-double-escaped(n) ::= s-white* “\” b-non-content l-empty(n,flow-in)* s-flow-line-prefix(n)
  // [113] s-double-break(n) ::= s-double-escaped(n) | s-flow-folded(n)
  // [114] nb-ns-double-in-line ::= ( s-white* ns-double-char )*
  // [115] s-double-next-line(n) ::= s-double-break(n) ( ns-double-char nb-ns-double-in-line ( s-double-next-line(n) | s-white* ) )?
  // [116] nb-double-multi-line(n) ::= nb-ns-double-in-line ( s-double-next-line(n) | s-white* )
  // [117] c-quoted-quote ::= “'” “'”
  // [118] nb-single-char ::= c-quoted-quote | ( nb-json - “'” )
  // [119] ns-single-char ::= nb-single-char - s-white
  // [120] c-single-quoted(n,c) ::= “'” nb-single-text(n,c) “'”
  // [121] nb-single-text(n,c) ::= c = flow-out ⇒ nb-single-multi-line(n) c = flow-in ⇒ nb-single-multi-line(n) c = block-key ⇒ nb-single-one-line c = flow-key ⇒ nb-single-one-line
  // [122] nb-single-one-line ::= nb-single-char*
  // [123] nb-ns-single-in-line ::= ( s-white* ns-single-char )*
  // [124] s-single-next-line(n) ::= s-flow-folded(n) ( ns-single-char nb-ns-single-in-line ( s-single-next-line(n) | s-white* ) )?
  // [125] nb-single-multi-line(n) ::= nb-ns-single-in-line ( s-single-next-line(n) | s-white* )
  // [126] ns-plain-first(c) ::= ( ns-char - c-indicator ) | ( ( “?” | “:” | “-” ) /* Followed by an ns-plain-safe(c)) */ )
  // [127] ns-plain-safe(c) ::= c = flow-out ⇒ ns-plain-safe-out c = flow-in ⇒ ns-plain-safe-in c = block-key ⇒ ns-plain-safe-out c = flow-key ⇒ ns-plain-safe-in
  // [128] ns-plain-safe-out ::= ns-char
  // [129] ns-plain-safe-in ::= ns-char - c-flow-indicator
  // [130] ns-plain-char(c) ::= ( ns-plain-safe(c) - “:” - “#” ) | ( /* An ns-char preceding */ “#” ) | ( “:” /* Followed by an ns-plain-safe(c) */ )
  // [131] ns-plain(n,c) ::= c = flow-out ⇒ ns-plain-multi-line(n,c) c = flow-in ⇒ ns-plain-multi-line(n,c) c = block-key ⇒ ns-plain-one-line(c) c = flow-key ⇒ ns-plain-one-line(c)
  // [132] nb-ns-plain-in-line(c) ::= ( s-white* ns-plain-char(c) )*
  // [133] ns-plain-one-line(c) ::= ns-plain-first(c) nb-ns-plain-in-line(c)
  // [134] s-ns-plain-next-line(n,c) ::= s-flow-folded(n) ns-plain-char(c) nb-ns-plain-in-line(c)
  // [135] ns-plain-multi-line(n,c) ::= ns-plain-one-line(c) s-ns-plain-next-line(n,c)*
  // [136] in-flow(c) ::= c = flow-out ⇒ flow-in c = flow-in ⇒ flow-in c = block-key ⇒ flow-key c = flow-key ⇒ flow-key
  // [137] c-flow-sequence(n,c) ::= “[” s-separate(n,c)? ns-s-flow-seq-entries(n,in-flow(c))? “]”
  // [138] ns-s-flow-seq-entries(n,c) ::= ns-flow-seq-entry(n,c) s-separate(n,c)? ( “,” s-separate(n,c)? ns-s-flow-seq-entries(n,c)? )?
  // [139] ns-flow-seq-entry(n,c) ::= ns-flow-pair(n,c) | ns-flow-node(n,c)
  // [140] c-flow-mapping(n,c) ::= “{” s-separate(n,c)? ns-s-flow-map-entries(n,in-flow(c))? “}”
  // [141] ns-s-flow-map-entries(n,c) ::= ns-flow-map-entry(n,c) s-separate(n,c)? ( “,” s-separate(n,c)? ns-s-flow-map-entries(n,c)? )?
  // [142] ns-flow-map-entry(n,c) ::= ( “?” s-separate(n,c) ns-flow-map-explicit-entry(n,c) ) | ns-flow-map-implicit-entry(n,c)
  // [143] ns-flow-map-explicit-entry(n,c) ::= ns-flow-map-implicit-entry(n,c) | ( e-node /* Key */ e-node /* Value */ )
  // [144] ns-flow-map-implicit-entry(n,c) ::= ns-flow-map-yaml-key-entry(n,c) | c-ns-flow-map-empty-key-entry(n,c) | c-ns-flow-map-json-key-entry(n,c)
  // [145] ns-flow-map-yaml-key-entry(n,c) ::= ns-flow-yaml-node(n,c) ( ( s-separate(n,c)? c-ns-flow-map-separate-value(n,c) ) | e-node )
  // [146] c-ns-flow-map-empty-key-entry(n,c) ::= e-node /* Key */ c-ns-flow-map-separate-value(n,c)
  // [147] c-ns-flow-map-separate-value(n,c) ::= “:” /* Not followed by an ns-plain-safe(c) */ ( ( s-separate(n,c) ns-flow-node(n,c) ) | e-node /* Value */ )
  // [148] c-ns-flow-map-json-key-entry(n,c) ::= c-flow-json-node(n,c) ( ( s-separate(n,c)? c-ns-flow-map-adjacent-value(n,c) ) | e-node )
  // [149] c-ns-flow-map-adjacent-value(n,c) ::= “:” ( ( s-separate(n,c)? ns-flow-node(n,c) ) | e-node ) /* Value */
  // [150] ns-flow-pair(n,c) ::= ( “?” s-separate(n,c) ns-flow-map-explicit-entry(n,c) ) | ns-flow-pair-entry(n,c)
  // [151] ns-flow-pair-entry(n,c) ::= ns-flow-pair-yaml-key-entry(n,c) | c-ns-flow-map-empty-key-entry(n,c) | c-ns-flow-pair-json-key-entry(n,c)
  // [152] ns-flow-pair-yaml-key-entry(n,c) ::= ns-s-implicit-yaml-key(flow-key) c-ns-flow-map-separate-value(n,c)
  // [153] c-ns-flow-pair-json-key-entry(n,c) ::= c-s-implicit-json-key(flow-key) c-ns-flow-map-adjacent-value(n,c)
  // [154] ns-s-implicit-yaml-key(c) ::= ns-flow-yaml-node(n/a,c) s-separate-in-line? /* At most 1024 characters altogether */
  // [155] c-s-implicit-json-key(c) ::= c-flow-json-node(n/a,c) s-separate-in-line? /* At most 1024 characters altogether */
  // [156] ns-flow-yaml-content(n,c) ::= ns-plain(n,c)
  // [157] c-flow-json-content(n,c) ::= c-flow-sequence(n,c) | c-flow-mapping(n,c) | c-single-quoted(n,c) | c-double-quoted(n,c)
  // [158] ns-flow-content(n,c) ::= ns-flow-yaml-content(n,c) | c-flow-json-content(n,c)
  // [159] ns-flow-yaml-node(n,c) ::= c-ns-alias-node | ns-flow-yaml-content(n,c) | ( c-ns-properties(n,c) ( ( s-separate(n,c) ns-flow-yaml-content(n,c) ) | e-scalar ) )
  // [160] c-flow-json-node(n,c) ::= ( c-ns-properties(n,c) s-separate(n,c) )? c-flow-json-content(n,c)
  // [161] ns-flow-node(n,c) ::= c-ns-alias-node | ns-flow-content(n,c) | ( c-ns-properties(n,c) ( ( s-separate(n,c) ns-flow-content(n,c) ) | e-scalar ) )
  // [162] c-b-block-header(m,t) ::= ( ( c-indentation-indicator(m) c-chomping-indicator(t) ) | ( c-chomping-indicator(t) c-indentation-indicator(m) ) ) s-b-comment
  // [163] c-indentation-indicator(m) ::= ns-dec-digit ⇒ m = ns-dec-digit - #x30 /* Empty */ ⇒ m = auto-detect()
  // [164] c-chomping-indicator(t) ::= “-” ⇒ t = strip “+” ⇒ t = keep /* Empty */ ⇒ t = clip
  // [165] b-chomped-last(t) ::= t = strip ⇒ b-non-content | /* End of file */ t = clip ⇒ b-as-line-feed | /* End of file */ t = keep ⇒ b-as-line-feed | /* End of file */
  // [166] l-chomped-empty(n,t) ::= t = strip ⇒ l-strip-empty(n) t = clip ⇒ l-strip-empty(n) t = keep ⇒ l-keep-empty(n)
  // [167] l-strip-empty(n) ::= ( s-indent(≤n) b-non-content )* l-trail-comments(n)?
  // [168] l-keep-empty(n) ::= l-empty(n,block-in)* l-trail-comments(n)?
  // [169] l-trail-comments(n) ::= s-indent(<n) c-nb-comment-text b-comment l-comment*
  // [170] c-l+literal(n) ::= “|” c-b-block-header(m,t) l-literal-content(n+m,t)
  // [171] l-nb-literal-text(n) ::= l-empty(n,block-in)* s-indent(n) nb-char+
  // [172] b-nb-literal-next(n) ::= b-as-line-feed l-nb-literal-text(n)
  // [173] l-literal-content(n,t) ::= ( l-nb-literal-text(n) b-nb-literal-next(n)* b-chomped-last(t) )? l-chomped-empty(n,t)
  // [174] c-l+folded(n) ::= “>” c-b-block-header(m,t) l-folded-content(n+m,t)
  // [175] s-nb-folded-text(n) ::= s-indent(n) ns-char nb-char*
  // [176] l-nb-folded-lines(n) ::= s-nb-folded-text(n) ( b-l-folded(n,block-in) s-nb-folded-text(n) )*
  // [177] s-nb-spaced-text(n) ::= s-indent(n) s-white nb-char*
  // [178] b-l-spaced(n) ::= b-as-line-feed l-empty(n,block-in)*
  // [179] l-nb-spaced-lines(n) ::= s-nb-spaced-text(n) ( b-l-spaced(n) s-nb-spaced-text(n) )*
  // [180] l-nb-same-lines(n) ::= l-empty(n,block-in)* ( l-nb-folded-lines(n) | l-nb-spaced-lines(n) )
  // [181] l-nb-diff-lines(n) ::= l-nb-same-lines(n) ( b-as-line-feed l-nb-same-lines(n) )*
  // [182] l-folded-content(n,t) ::= ( l-nb-diff-lines(n) b-chomped-last(t) )? l-chomped-empty(n,t)
  // [183] l+block-sequence(n) ::= ( s-indent(n+m) c-l-block-seq-entry(n+m) )+ /* For some fixed auto-detected m > 0 */
  // [184] c-l-block-seq-entry(n) ::= “-” /* Not followed by an ns-char */ s-l+block-indented(n,block-in)
  // [185] s-l+block-indented(n,c) ::= ( s-indent(m) ( ns-l-compact-sequence(n+1+m) | ns-l-compact-mapping(n+1+m) ) ) | s-l+block-node(n,c) | ( e-node s-l-comments )
  // [186] ns-l-compact-sequence(n) ::= c-l-block-seq-entry(n) ( s-indent(n) c-l-block-seq-entry(n) )*
  // [187] l+block-mapping(n) ::= ( s-indent(n+m) ns-l-block-map-entry(n+m) )+ /* For some fixed auto-detected m > 0 */
  // [188] ns-l-block-map-entry(n) ::= c-l-block-map-explicit-entry(n) | ns-l-block-map-implicit-entry(n)
  // [189] c-l-block-map-explicit-entry(n) ::= c-l-block-map-explicit-key(n) ( l-block-map-explicit-value(n) | e-node )
  // [190] c-l-block-map-explicit-key(n) ::= “?” s-l+block-indented(n,block-out)
  // [191] l-block-map-explicit-value(n) ::= s-indent(n) “:” s-l+block-indented(n,block-out)
  fun l_block_map_explicit_value(n: U16) =>
    s_indent(n)
    chars(":")
    s_l_block_indented(n, _BlockOut)

  // [192] ns-l-block-map-implicit-entry(n) ::= ( ns-s-block-map-implicit-key | e-node ) c-l-block-map-implicit-value(n)
  fun ns_l_block_map_implici_entry(n: U16) =>
    ns_s_block_map_implicit_key()
    e_node()
    c_l_block_map_implicit_value(n)

  // [193] ns-s-block-map-implicit-key ::= c-s-implicit-json-key(block-key) | ns-s-implicit-yaml-key(block-key)
  fun ns_s_block_map_implicit_key() =>
    c_s_implicit_json_key(_BlockKey)
    ns_s_implicit_yamp_key(_BlockKey)

  // [194] c-l-block-map-implicit-value(n) ::= “:” ( s-l+block-node(n,block-out) | ( e-node s-l-comments ) )
  c_l_block_map_implicit_value(n: U16) =>
    chars(":")
    s_l_block_node(n, _BlockOut)
    e_node()
    s_l_comments()

  // [195] ns-l-compact-mapping(n) ::= ns-l-block-map-entry(n) ( s-indent(n) ns-l-block-map-entry(n) )*
  fun ns_l_compact_mapping(n: U16) =>
    ns_l_block_map_entry(n)
    s_indent(n)
    ns_l_block_map_entry(n)

  // [196] s-l+block-node(n,c) ::= s-l+block-in-block(n,c) | s-l+flow-in-block(n)
  fun s_l_block_node(n: U16, c: _ParseContext) =>
    s_l_block_in_bock(n, c)
    s_l_flow_in_block(n)

  // [197] s-l+flow-in-block(n) ::= s-separate(n+1,flow-out) ns-flow-node(n+1,flow-out) s-l-comments
  fun s_l_flow_in_block(n) =>
    s_separate(n+1, _FlowOut)
    ns_flow_node(n+1, _FlowOut)
    s_l_comments()

  // [198] s-l+block-in-block(n,c) ::= s-l+block-scalar(n,c) | s-l+block-collection(n,c)
  fun s_l_block_in_bock(n: U16, c: _ParseContext) =>
    s_l_block_scalar(n, c)
    s_l_block_collection(n , c)

  // [199] s-l+block-scalar(n,c) ::= s-separate(n+1,c) ( c-ns-properties(n+1,c) s-separate(n+1,c) )? ( c-l+literal(n) | c-l+folded(n) )
  fun s_l_block_scalar(n: U16, c: _ParseContext) =>
    s_separate(n+1, c)
    c_ns_properties(n+1, c)
    s_separate(n+1, c)
    c_l_literal(n)
    c_l_folded(n)

  // [200] s-l+block-collection(n,c) ::= ( s-separate(n+1,c) c-ns-properties(n+1,c) )? s-l-comments ( l+block-sequence(seq-spaces(n,c)) | l+block-mapping(n) )
  fun s_l_block_collection(n: U16, c: _ParseContext) =>
    s_separate(n+1, c)
    c_ns_properties(n+1, c)
    s_l_comments()
    l_block_sequence(seq_qpaces(n, c))
    l_block_mapping(n)

  // [201] seq-spaces(n,c) ::= c = block-out ⇒ n-1 c = block-in ⇒ n
  fun seq_spaces(n: U16, c: _ParseContext): U16 =>
    match c
    | _BlockOut => n-1
    | _BlockIn => n
    end

  // [202] l-document-prefix ::= c-byte-order-mark? l-comment*
  fun l_document_prefix()
    c_byte_order_mark()
    l_comments()

  // [203] c-directives-end ::= “-” “-” “-”
  fun c_directives_end() =>
    chars("---")

  // [204] c-document-end ::= “.” “.” “.”
  fun c_document_end() =>
    chars("...")

  // [205] l-document-suffix ::= c-document-end s-l-comments
  fun l_document_suffix() =>
    c_document_end()
    s_l_comments()

  // [206] c-forbidden ::= /* Start of line */ ( c-directives-end | c-document-end ) ( b-char | s-white | /* End of file */ )
  fun c_forbidden() =>

  // [207] l-bare-document ::= s-l+block-node(-1,block-in) /* Excluding c-forbidden content */
  fun l_bare_document() =>
    s_l_block_node(-1, _BlockIn)

  // [208] l-explicit-document ::= c-directives-end ( l-bare-document | ( e-node s-l-comments ) )
  fun l_explicitDocument() =>
    c_directive_end()
    let doc = l_bare_document()
    if doc == None then
      e_node()
      s_l_comments()
    end

  // [209] l-directive-document ::= l-directive+ l-explicit-document
  fun l_directive_ocument() =>
    var dir
    do
      dir = l_directive()
    while dir != None end
    let doc = l_explicit_document()
    return doc

  // [210] l-any-document ::= l-directive-document | l-explicit-document | l-bare-document
  fun l_any_ocument() =>
    let doc = l_directive_document()
    if doc == None then
    doc = l_explicit_document()
    end
    if doc == None then
    doc = l_bare_document()
    end
    return doc

  // [211]	l-yaml-stream	::=	l-document-prefix* l-any-document? ( l-document-suffix+ l-document-prefix* l-any-document? | l-document-prefix* l-explicit-document? )*
  fun l_yaml_stream() =>
    let prefix = l_document_prefix()
    let doc = l_any_document()
    while true do
      let suffix = l_document_suffix()
      l_document_prefix()
      l_any_document()
      l_document_prefix()
      l_explicit_document()
    end
