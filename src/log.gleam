import gleam/io

const reset = "\u{1B}[0m"

const green = "\u{1B}[32m"

const bold = "\u{1B}[1m"

const grey = "\u{1B}[90m"

pub fn section(name: String) -> Nil {
  io.println("")
  io.println(bold <> "=== " <> name <> " ===" <> reset)
  io.println("")
}

pub fn pass(name: String) -> Nil {
  io.println(green <> "  ✓ " <> name <> reset)
}

pub fn running(name: String) -> Nil {
  io.println("  " <> name <> "...")
}

pub fn debug(value: String) -> Nil {
  io.println(grey <> "  [debug] " <> value <> reset)
}
