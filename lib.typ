#import "@preview/rubby:0.10.2": get-ruby

// Load the WASM plugin
#let mando = plugin("rust_mando.wasm")

// ── internal helpers ──────────────────────────────────────────────────────────

/// Recursively extract plain text from a content value.
/// Paragraph breaks become "\n\n", line breaks become "\n".
#let _extract-text(it) = {
  if type(it) == str {
    it
  } else if type(it) == content {
    if it == parbreak()        { "\n\n" }
    else if it == linebreak()  { "\n" }
    else if it.has("text")     { it.text }
    else if it.has("children") { it.children.map(_extract-text).join("") }
    else if it.has("body")     { _extract-text(it.body) }
    else { "" }
  } else { "" }
}

// ── low-level API ─────────────────────────────────────────────────────────────

/// Returns a flat space-separated pīnyīn string (non-Chinese tokens omitted).
/// `style`: "marks" (default) or "numbers"
#let flat(txt, style: "marks") = str(
  mando.pinyin_flat(bytes(txt), bytes(style))
)

/// Returns a raw array of segment dicts: `{word, pinyin}`.
/// `pinyin` is `none` for non-Chinese tokens (punctuation, spaces, Latin).
/// `style`: "marks" (default) or "numbers"
#let segment(txt, style: "marks") = json(
  mando.pinyin_segmented(bytes(txt), bytes(style))
)

/// Segments content (not just strings) by first extracting its plain text.
#let segment-content(it, style: "marks") = segment(
  _extract-text(it), style: style
)

// ── ruby renderer ─────────────────────────────────────────────────────────────

/// Build a `ruby` function from `rubby` with sensible defaults for pīnyīn.
/// Override any parameter by calling `get-ruby(...)` yourself and passing
/// the result as `ruby-fn`.
#let _default-ruby = get-ruby(
  size:         0.7em,
  dy:           0pt,
  pos:          top,
  alignment:    "center",
  delimiter:    "|",
  auto-spacing: true,
)

/// Render one segment dict `{word, pinyin}` as ruby-annotated content.
/// - Chinese words: each character gets its syllable above it.
/// - Non-Chinese tokens (`pinyin: none`): rendered as plain text.
/// Note: newline handling (linebreak vs parbreak) is done in render-segments,
/// which can inspect neighbouring segments.
#let _render-segment(seg, ruby-fn: _default-ruby) = {
  if seg.pinyin == none {
    if seg.word == "\n" { linebreak() }
    else { seg.word }
  } else {
    // Join syllables with the rubby delimiter so each character gets
    // its own annotation: ruby[nǐ|hǎo][你|好]
    let annotation = seg.pinyin.join("|")
    let base       = seg.word.clusters().join("|")
    (ruby-fn)(annotation, base)
  }
}

/// Render an array of segment dicts as ruby-annotated content.
///
/// Parameters:
/// - `segs`     — array returned by `segment()` or `segment-content()`
/// - `ruby-fn`  — optional custom ruby function from `get-ruby(...)`
///                (defaults to 0.5em, top, center alignment)
/// - `word-sep` — horizontal gap inserted between consecutive Chinese word
///                segments so word boundaries are visible in the base text
///                line (default: 0.25em). Pass `0em` to disable.
///
/// Example:
/// ```typst
/// #render-segments(segment("北京歡迎你"))
/// #render-segments(segment("北京歡迎你"), word-sep: 0.4em)
/// ```
#let render-segments(segs, ruby-fn: _default-ruby, word-sep: 0.25em) = {
  let n = segs.len()
  // Iterate by index so we can look ahead for double-\n → parbreak.
  let i = 0
  while i < n {
    let seg  = segs.at(i)
    let next = if i + 1 < n { segs.at(i + 1) } else { none }

    // Two consecutive \n segments → paragraph break (consume both).
    if seg.word == "\n" and next != none and next.word == "\n" {
      parbreak()
      i += 2
      continue
    }

    // Insert a fixed horizontal gap between two consecutive Chinese word
    // segments so word boundaries are visible in the base text line.
    if word-sep != 0em and i > 0 {
      let prev = segs.at(i - 1)
      if seg.pinyin != none and prev.pinyin != none {
        h(word-sep)
      }
    }

    _render-segment(seg, ruby-fn: ruby-fn)
    i += 1
  }
}

/// High-level function: annotate Chinese text (string or content) with
/// pīnyīn ruby above each character.
///
/// Parameters:
/// - `it`       — string or content block (supports inline markup)
/// - `style`    — `"marks"` (default) or `"numbers"`
/// - `ruby-fn`  — optional custom ruby function from `get-ruby(...)`
/// - `word-sep` — horizontal gap between consecutive Chinese word segments
///                (default: 0.25em). Pass `0em` to disable.
/// - `leading`  — line spacing, passed to `par(leading: ...)` to prevent
///                ruby annotations from overlapping the line above
///                (default: 1.5em — increase if using a larger ruby size)
///
/// Example:
/// ```typst
/// #mando-ruby[北京歡迎你！]
/// #mando-ruby(style: "numbers")[北京]
/// #mando-ruby(word-sep: 0em)[北京歡迎你]    // no word gap
/// #mando-ruby(word-sep: 0.4em)[北京歡迎你]  // wider gap
/// #mando-ruby(leading: 2em)[...]            // more line spacing
///
/// // Custom ruby size:
/// #let big-ruby = get-ruby(size: 0.7em, pos: top, alignment: "center", delimiter: "|")
/// #mando-ruby(ruby-fn: big-ruby)[北京歡迎你]
/// ```
#let mando-ruby(it, style: "marks", ruby-fn: _default-ruby, word-sep: 0.25em, leading: 1.5em) = {
  set par(leading: leading)
  render-segments(
    segment-content(it, style: style),
    ruby-fn:  ruby-fn,
    word-sep: word-sep,
  )
}
