# auto-mando

`auto-mando` is a Typst plugin that provides automatic conversion of Chinese
characters (Hanzi) into Mandarin romanization (Pīnyīn). It leverages a
high-performance Rust-based WASM plugin to segment text and apply ruby
annotations.

## Features

* **Automatic Segmentation**: Accurately splits Chinese sentences into words to
  ensure correct pīnyīn placement.
* **Ruby Annotation**: Automatically places pīnyīn above characters using the
  `rubby` package.
* **Formatting Support**: Supports both tone marks (default) and tone numbers
  (e.g., `nǐ` vs `ni3`).
* **Content-Aware**: Processes both plain strings and Typst content blocks,
  preserving line breaks and paragraph breaks.

## Usage
### Basic Example

Simply wrap your text in `#mando-ruby[...]` to get automatic annotations.

```typst
#import "@preview/auto-mando:0.1.0": mando-ruby

#set text(font: ("Libertinus Serif", "Noto Serif CJK TC"), size: 18pt)

#mando-ruby[北京歡迎你！]
```

> **Note**: At larger font sizes the pīnyīn annotations may overlap the line
> above. Increase the `leading` parameter if needed:
>
> ```typst
> #mando-ruby(leading: 2em)[北京歡迎你！]
> ```

### Customized Display

It's possible to specify the word separation.

```typst
#import "@preview/auto-mando:0.1.0": mando-ruby
#set text(24pt, font: ("Libertinus Serif", "AR PL KaitiM Big5"))
#mando-ruby(word-sep: 0.7em)[
  北京歡迎你們！

  你們今天過得怎麼樣

  world, 你可以幫幫我嗎？

  能不能告訴我現在你在做甚麼？
]
```

![sample output](example.png)

### Tone Styles

You can switch between standard tone marks and tone numbers using the `style`
parameter.

```typst
#import "@preview/auto-mando:0.1.0": mando-ruby

// Using tone numbers
#mando-ruby(style: "numbers")[北京]
```

### Customizing Ruby Style

If you want to change the size, position, or color of the pīnyīn, you can
create a custom ruby function using `get-ruby`.

```typst
#import "@preview/auto-mando:0.1.0": mando-ruby, get-ruby

#let my-style = get-ruby(
  size: 0.7em, 
  pos: top, 
  alignment: "center", 
  delimiter: "|"
)

#mando-ruby(ruby-fn: my-style)[北京歡迎你]
```

## API Reference
### `mando-ruby(it, style: "marks", ruby-fn: _default-ruby, word-sep: 0.25em, leading: 1.5em)`

The primary high-level function for annotating text.

* `it`: The string or content block to annotate.
* `style`: Either `"marks"` or `"numbers"`.
* `ruby-fn`: A custom renderer function.
* `word-sep`: Horizontal gap between consecutive Chinese words (default
  `0.25em`). Pass `0em` to disable.
* `leading`: Line spacing passed to `par(leading: ...)` to prevent ruby
  annotations from overlapping the line above (default `1.5em`).

### `flat(txt, style: "marks")`

Returns a space-separated pīnyīn string, useful for metadata or simple text
processing.

### `segment(txt, style: "marks")`

A low-level function that returns an array of dictionaries containing the word
and its corresponding pīnyīn syllables.

## Technical Details

* **WASM Backend**: Powered by `rust_mando.wasm` for fast, memory-efficient
  processing.
* **Compiler Requirements**: Requires Typst compiler version `0.14.0` or
  higher.
* **License**: MIT.

## Author

* Vincent Tam ([GitHub](https://github.com/VincentTam)).
