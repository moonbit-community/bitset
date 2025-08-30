///|
fn main {
  let bs = @lib.BitSet::new(100)

  // Demo basic operations
  println("=== BitSet Demo ===")
  try {
    ignore(bs.set(10))
    ignore(bs.set(20))
    ignore(bs.set(30))
  } catch {
    _ => println("Error setting bits")
  }
  println("Set bits at positions 10, 20, 30")
  println("Bit 10 is set: " + bs.test_bit(10).to_string())
  println("Bit 15 is set: " + bs.test_bit(15).to_string())
  println("Bit 20 is set: " + bs.test_bit(20).to_string())
  ignore(bs.clear(20))
  println("After clearing bit 20:")
  println("Bit 20 is set: " + bs.test_bit(20).to_string())
  println("BitSet length: " + bs.len().to_string())
}
