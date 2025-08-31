# BitSet

*MoonBit library to map between non-negative integers and boolean values*

This library implements bitsets, a mapping between non-negative integers and boolean values.
It should be more efficient than `Map[UInt, Bool]`.

This is a MoonBit translation of the [bits-and-blooms/bitset](https://github.com/bits-and-blooms/bitset) Go library.

## Description

Package bitset implements bitsets, a mapping between non-negative integers and boolean values.
It provides methods for setting, clearing, flipping, and testing individual integers.

It also provides set intersection, union, difference, complement, and symmetric operations, 
as well as tests to check whether any, all, or no bits are set, and querying a bitset's current 
length and number of positive bits.

BitSets are expanded to the size of the largest set bit; the memory allocation is approximately 
Max bits, where Max is the largest set bit. BitSets are never shrunk automatically, but `shrink` 
and `compact` methods are available. On creation, a hint can be given for the number of bits that will be used.

Many of the methods, including `set`, `clear`, and `flip`, return a BitSet pointer, which allows for chaining.

## Creating BitSets

```moonbit
test "create bitsets" {
  // Create a new BitSet with hint for expected size
  let bs1 = @bitset.BitSet::new(100)
  inspect(bs1.len(), content="100")
  
  // Create an empty BitSet
  let bs2 = @bitset.BitSet::empty()
  inspect(bs2.len(), content="0")
  
  // Initially no bits are set
  inspect(bs1.any(), content="false")
  inspect(bs2.any(), content="false")
}
```

## Setting and Testing Bits

```moonbit
test "basic bit operations" {
  let bs = @bitset.BitSet::new(100)
  
  // Set some bits (chainable operations)
  try {
    bs.set(10)
    bs.set(20)
    bs.set(30)
  } catch {
    _ => ()
  }
  
  // Test bits
  inspect(bs.test_bit(10), content="true")   // bit 10 is set
  inspect(bs.test_bit(15), content="false")  // bit 15 is not set
  inspect(bs.test_bit(20), content="true")   // bit 20 is set
  
  // Clear a bit
  bs.clear(20)
  inspect(bs.test_bit(20), content="false")  // bit 20 is now clear
  
  // Count set bits
  inspect(bs.count(), content="2")  // bits 10 and 30 are still set
}
```

## Set Operations

```moonbit
test "set operations" {
  let bs1 = @bitset.BitSet::new(50)
  let bs2 = @bitset.BitSet::new(50)
  
  // Set up test data
  try {
    bs1.set(1)
    bs1.set(3)
    bs1.set(5)
    bs2.set(3)
    bs2.set(5)
    bs2.set(7)
  } catch {
    _ => ()
  }
  
  // Union (OR)
  let union_result = bs1.union(bs2)
  inspect(union_result.test_bit(1), content="true")  // from bs1
  inspect(union_result.test_bit(3), content="true")  // from both
  inspect(union_result.test_bit(7), content="true")  // from bs2
  
  // Intersection (AND)
  let intersection = bs1.intersection(bs2)
  inspect(intersection.test_bit(1), content="false") // only in bs1
  inspect(intersection.test_bit(3), content="true")  // in both
  inspect(intersection.test_bit(5), content="true")  // in both
  inspect(intersection.test_bit(7), content="false") // only in bs2
  
  // Difference (AND NOT)
  let difference = bs1.difference(bs2)
  inspect(difference.test_bit(1), content="true")    // in bs1 but not bs2
  inspect(difference.test_bit(3), content="false")   // in both
  inspect(difference.test_bit(7), content="false")   // not in bs1
}
```

## Querying BitSet State

```moonbit
test "bitset state queries" {
  let empty_bs = @bitset.BitSet::empty()
  let partial_bs = @bitset.BitSet::new(10)
  let full_bs = @bitset.BitSet::new(5)
  
  // Set some bits in partial_bs
  try {
    partial_bs.set(2)
    partial_bs.set(7)
  } catch {
    _ => ()
  }
  
  // Set all bits in full_bs
  try {
    for i = 0; i < 5; i = i + 1 {
      full_bs.set(i.reinterpret_as_uint())
    }
  } catch {
    _ => ()
  }
  
  // Test any()
  inspect(empty_bs.any(), content="false")
  inspect(partial_bs.any(), content="true")
  inspect(full_bs.any(), content="true")
  
  // Test none()
  inspect(empty_bs.none(), content="true")
  inspect(partial_bs.none(), content="false")
  inspect(full_bs.none(), content="false")
  
  // Test count()
  inspect(empty_bs.count(), content="0")
  inspect(partial_bs.count(), content="2")
  inspect(full_bs.count(), content="5")
}
```

## Finding Set and Clear Bits

```moonbit
test "finding bits" {
  let bs = @bitset.BitSet::new(20)
  
  // Set bits at positions 5, 10, 15
  try {
    bs.set(5)
    bs.set(10)
    bs.set(15)
  } catch {
    _ => ()
  }
  
  // Find next set bit from position 0
  let (pos1, found1) = bs.next_set(0)
  inspect(found1, content="true")
  inspect(pos1, content="5")
  
  // Find next set bit from position 6
  let (pos2, found2) = bs.next_set(6)
  inspect(found2, content="true")
  inspect(pos2, content="10")
  
  // Find next clear bit from position 0
  let (pos3, found3) = bs.next_clear(0)
  inspect(found3, content="true")
  inspect(pos3, content="0")  // bit 0 is clear
  
  // Find previous set bit from position 12
  let (pos4, found4) = bs.previous_set(12)
  inspect(found4, content="true")
  inspect(pos4, content="10")
}
```

## Bit Manipulation Operations

```moonbit
test "bit manipulation" {
  let bs = @bitset.BitSet::new(10)
  
  // Set bit to specific value
  try {
    bs.set_to(3, true)   // set bit 3
    bs.set_to(5, false)  // clear bit 5
  } catch {
    _ => ()
  }
  
  inspect(bs.test_bit(3), content="true")
  inspect(bs.test_bit(5), content="false")
  
  // Flip bits
  try {
    bs.flip(3)  // flip bit 3 (true -> false)
    bs.flip(5)  // flip bit 5 (false -> true)
  } catch {
    _ => ()
  }
  
  inspect(bs.test_bit(3), content="false")
  inspect(bs.test_bit(5), content="true")
}
```

## Cloning and Equality

```moonbit
test "clone and equality" {
  let bs1 = @bitset.BitSet::new(20)
  
  try {
    bs1.set(1)
    bs1.set(5)
    bs1.set(10)
  } catch {
    _ => ()
  }
  
  // Clone the bitset
  let bs2 = bs1.clone()
  
  // Test equality
  inspect(bs1.equal(bs2), content="true")
  
  // Modify original
  bs1.clear(5)
  
  // Should no longer be equal
  inspect(bs1.equal(bs2), content="false")
  
  // Clone should still have bit 5 set
  inspect(bs2.test_bit(5), content="true")
  inspect(bs1.test_bit(5), content="false")
}
```

## API Reference

### Creation and Basic Operations

- `BitSet::new(length : UInt) -> BitSet` - Create a new BitSet with hint for expected size
- `BitSet::empty() -> BitSet` - Create an empty BitSet
- `set(self : BitSet, i : UInt) -> Unit` - Set bit i to 1 (chainable with ..)
- `clear(self : BitSet, i : UInt) -> Unit` - Clear bit i to 0 (chainable with ..)
- `test_bit(self : BitSet, i : UInt) -> Bool` - Test if bit i is set
- `flip(self : BitSet, i : UInt) -> Unit` - Flip bit i (chainable with ..)
- `set_to(self : BitSet, i : UInt, value : Bool) -> Unit` - Set bit i to value

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
