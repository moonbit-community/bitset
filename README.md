# BitSet

*MoonBit library to map between non-negative integers and boolean values*

This library implements bitsets, a mapping between non-negative integers and boolean values.
It should be more efficient than `Map[UInt, Bool]`.

This is a MoonBit translation of the [bits-and-blooms/bitset](https://github.com/bits-and-blooms/bitset) Go library.

## Description

Package bitset implements bitsets, a mapping between non-negative integers and boolean values.
It provides methods for setting, clearing, flipping, and testing individual integers.

But it also provides set intersection, union, difference, complement, and symmetric operations, 
as well as tests to check whether any, all, or no bits are set, and querying a bitset's current 
length and number of positive bits.

BitSets are expanded to the size of the largest set bit; the memory allocation is approximately 
Max bits, where Max is the largest set bit. BitSets are never shrunk automatically, but `shrink` 
and `compact` methods are available. On creation, a hint can be given for the number of bits that will be used.

Many of the methods, including `set`, `clear`, and `flip`, return a BitSet pointer, which allows for chaining.

## Example Usage

```moonbit
fn main {
  let bs = BitSet::new(100)
  
  // Set some bits
  try {
    ignore(bs.set(10).set(20).set(30))
  } catch {
    _ => ()
  }
  
  // Test bits
  println("Bit 10 is set: " + bs.test_bit(10).to_string())  // true
  println("Bit 15 is set: " + bs.test_bit(15).to_string())  // false
  
  // Clear a bit
  ignore(bs.clear(20))
  println("Bit 20 is set: " + bs.test_bit(20).to_string())  // false
  
  // Count set bits
  println("Number of set bits: " + bs.count().to_string())  // 2
  
  // Test for any/all/none
  println("Any bits set: " + bs.any().to_string())          // true
  println("All bits set: " + bs.all().to_string())          // false
  println("No bits set: " + bs.none().to_string())          // false
}
```

## API Reference

### Creation and Basic Operations

- `BitSet::new(length : UInt) -> BitSet` - Create a new BitSet with hint for expected size
- `BitSet::empty() -> BitSet` - Create an empty BitSet
- `set(self : BitSet, i : UInt) -> BitSet!` - Set bit i to 1 (chainable)
- `clear(self : BitSet, i : UInt) -> BitSet` - Clear bit i to 0 (chainable)
- `test_bit(self : BitSet, i : UInt) -> Bool` - Test if bit i is set
- `flip(self : BitSet, i : UInt) -> BitSet!` - Flip bit i (chainable)
- `set_to(self : BitSet, i : UInt, value : Bool) -> BitSet!` - Set bit i to value

### Size and Information

- `len(self : BitSet) -> UInt` - Return the length of the BitSet
- `count(self : BitSet) -> UInt` - Count the number of set bits (population count)
- `any(self : BitSet) -> Bool` - Return true if any bit is set
- `all(self : BitSet) -> Bool` - Return true if all bits are set
- `none(self : BitSet) -> Bool` - Return true if no bits are set

### Set Operations

- `intersection(self : BitSet, other : BitSet) -> BitSet` - Intersection (AND)
- `union(self : BitSet, other : BitSet) -> BitSet` - Union (OR)
- `difference(self : BitSet, other : BitSet) -> BitSet` - Difference (AND NOT)
- `symmetric_difference(self : BitSet, other : BitSet) -> BitSet` - Symmetric difference (XOR)
- `complement(self : BitSet) -> BitSet` - Complement (NOT)

### Iteration and Search

- `next_set(self : BitSet, i : UInt) -> (UInt, Bool)` - Find next set bit from index i
- `next_clear(self : BitSet, i : UInt) -> (UInt, Bool)` - Find next clear bit from index i
- `previous_set(self : BitSet, i : UInt) -> (UInt, Bool)` - Find previous set bit from index i
- `previous_clear(self : BitSet, i : UInt) -> (UInt, Bool)` - Find previous clear bit from index i

### Utility Operations

- `clone(self : BitSet) -> BitSet` - Create a copy of the BitSet
- `equal(self : BitSet, other : BitSet) -> Bool` - Test equality
- `to_string(self : BitSet) -> String` - String representation for debugging

## Building and Testing

```bash
# Build the project
moon check

# Run tests
moon test

# Run the demo
moon run cmd/main
```

## License

Apache-2.0 License (same as the original Go implementation)