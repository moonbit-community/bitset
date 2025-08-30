///|
/// Package bitset implements bitsets, a mapping between non-negative integers and boolean values.
/// It should be more efficient than Map[UInt, Bool].
///
/// It provides methods for setting, clearing, flipping, and testing individual integers.
/// But it also provides set intersection, union, difference, complement, and symmetric operations,
/// as well as tests to check whether any, all, or no bits are set, and querying a bitset's current
/// length and number of positive bits.
///
/// BitSets are expanded to the size of the largest set bit; the memory allocation is approximately
/// Max bits, where Max is the largest set bit. BitSets are never shrunk automatically.
/// On creation, a hint can be given for the number of bits that will be used.
///
/// Many of the methods, including set, clear, and flip, return a BitSet pointer,
/// which allows for chaining.

///|
/// The word size of a bit set
const WordSize : UInt = 64

///|
/// word_mask is word_size-1, used for bit indexing in a word
const WordMask : UInt = WordSize - 1

///|
/// log2_word_size is lg(word_size)
const Log2WordSize : UInt = 6

///|
/// all_bits has every bit set
const AllBits : UInt64 = 0xffffffffffffffff_UL

///|
/// A BitSet is a set of bits. The zero value of a BitSet is an empty set of length 0.
/// The internal representation is abstracted away from users.
struct BitSet {
  mut length : UInt
  // TODO: change to FixedArray for better performance
  mut set : Array[UInt64]
}

///|
/// Error type for BitSet operations
pub suberror BitSetError String

///|
/// Calculate the number of words needed for i bits
fn words_needed(i : UInt) -> Int {
  let cap = max_capacity()
  if i > cap - WordMask {
    (cap >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  } else {
    ((i + WordMask) >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  }
}

///|
/// Calculate the number of words needed for i bits, possibly exceeding the capacity.
/// This function is useful if you know that the capacity cannot be exceeded.
fn words_needed_unbound(i : UInt) -> Int {
  (i.reinterpret_as_int() + WordMask.reinterpret_as_int()) >>
  Log2WordSize.reinterpret_as_int()
}

///|
/// Calculate the index of words in a UInt64
fn words_index(i : UInt) -> UInt {
  i & WordMask
}

///|
/// Return the total possible capacity, or number of bits that can be stored in the BitSet theoretically.
pub fn max_capacity() -> UInt {
  0xFFFFFFFF_U // Maximum UInt value
}

///|
/// Create a new BitSet with a hint that length bits will be required.
/// The memory usage is at least length/8 bytes.
pub fn BitSet::new(length : UInt) -> BitSet {
  { length, set: Array::make(words_needed(length), 0UL) }
}

///|
/// Create a new empty BitSet.
pub fn BitSet::empty() -> BitSet {
  { length: 0, set: [] }
}

///|
/// Return the number of bits in the BitSet.
/// Note that it differs from count function.
pub fn len(self : BitSet) -> UInt {
  self.length
}

///|
/// Extend the BitSet to incorporate new bits if needed
fn extend_set(self : BitSet, i : UInt) -> Unit raise {
  if i >= max_capacity() {
    raise BitSetError("You are exceeding the capacity")
  }
  let nsize = words_needed(i + 1)
  if self.set.length() == 0 {
    self.set = Array::make(nsize, 0UL)
  } else if self.set.capacity() >= nsize {
    // Fast resize within existing capacity
    while self.set.length() < nsize {
      self.set.push(0UL)
    }
  } else if self.set.length() < nsize {
    // Need to grow the array
    let new_set = Array::make(nsize, 0UL)
    for i = 0; i < self.set.length(); i = i + 1 {
      new_set[i] = self.set[i]
    }
    self.set = new_set
  }
  self.length = i + 1
}

///|
/// Test whether bit i is set.
pub fn test_bit(self : BitSet, i : UInt) -> Bool {
  if i >= self.length {
    false
  } else {
    let word_idx = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
    let bit_idx = words_index(i)
    (self.set[word_idx] & (1UL << bit_idx.reinterpret_as_int())) != 0UL
  }
}

///|
/// Set bit i to 1, the capacity of the bitset is automatically increased accordingly.
/// Warning: using a very large value for 'i' may lead to a memory shortage and a panic.
/// The memory usage is at least slightly over i/8 bytes.
/// Use cascading operator for chaining: `bs..set(10)..set(20)..set(30)`
pub fn BitSet::set(self : BitSet, i : UInt) -> Unit raise {
  if i >= self.length {
    self.extend_set(i)
  }
  let word_idx = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  let bit_idx = words_index(i)
  self.set[word_idx] = self.set[word_idx] |
    (1UL << bit_idx.reinterpret_as_int())
}

///|
/// Clear bit i to 0. This never causes a memory allocation. It is always safe.
/// Use cascading operator for chaining: `bs..clear(10)..clear(20)..clear(30)`
pub fn BitSet::clear(self : BitSet, i : UInt) -> Unit {
  if i >= self.length {
    ()
  } else {
    let word_idx = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
    let bit_idx = words_index(i)
    self.set[word_idx] = self.set[word_idx] &
      (1UL << bit_idx.reinterpret_as_int()).lnot()
  }
}

///|
/// Set bit i to value.
/// Warning: using a very large value for 'i' may lead to a memory shortage and a panic.
/// Use cascading operator for chaining: `bs..set_to(10, true)..set_to(20, false)`
pub fn BitSet::set_to(self : BitSet, i : UInt, value : Bool) -> Unit raise {
  if value {
    self.set(i)
  } else {
    self.clear(i)
  }
}

///|
/// Flip bit at i.
/// Warning: using a very large value for 'i' may lead to a memory shortage and a panic.
/// Use cascading operator for chaining: `bs..flip(10)..flip(20)..flip(30)`
pub fn BitSet::flip(self : BitSet, i : UInt) -> Unit raise {
  if i >= self.length {
    self.set(i)
  } else {
    let word_idx = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
    let bit_idx = words_index(i)
    self.set[word_idx] = self.set[word_idx] ^
      (1UL << bit_idx.reinterpret_as_int())
  }
}

///|
/// Sort two BitSets by length (shorter first)
fn sort_by_length(a : BitSet, b : BitSet) -> (BitSet, BitSet) {
  if a.length <= b.length {
    (a, b)
  } else {
    (b, a)
  }
}

///|
/// Get the word count for a BitSet
fn word_count(self : BitSet) -> Int {
  words_needed_unbound(self.length)
}

///|
/// Clone this BitSet, returning a new BitSet that has the same bits set.
pub fn clone(self : BitSet) -> BitSet {
  let new_set = Array::make(self.set.length(), 0UL)
  for i = 0; i < self.set.length(); i = i + 1 {
    new_set[i] = self.set[i]
  }
  { length: self.length, set: new_set }
}

///|
/// Intersection of base set and other set (BitSet equivalent of & (and))
pub fn intersection(self : BitSet, other : BitSet) -> BitSet {
  let (shorter, longer) = sort_by_length(self, other)
  let result = BitSet::new(shorter.length)
  for i = 0; i < shorter.set.length(); i = i + 1 {
    result.set[i] = shorter.set[i] & longer.set[i]
  }
  result
}

///|
/// Union of base set and other set (BitSet equivalent of | (or))
pub fn union(self : BitSet, other : BitSet) -> BitSet {
  let (shorter, longer) = sort_by_length(self, other)
  let result = longer.clone()
  for i = 0; i < shorter.set.length(); i = i + 1 {
    result.set[i] = shorter.set[i] | longer.set[i]
  }
  result
}

///|
/// Difference of base set and other set (BitSet equivalent of &^ (and not))
pub fn difference(self : BitSet, other : BitSet) -> BitSet {
  let result = self.clone()
  let l = other.word_count().min(self.word_count())
  for i = 0; i < l; i = i + 1 {
    result.set[i] = self.set[i] & other.set[i].lnot()
  }
  result
}

///|
/// Symmetric difference of base set and other set (BitSet equivalent of ^ (xor))
pub fn symmetric_difference(self : BitSet, other : BitSet) -> BitSet {
  let (shorter, longer) = sort_by_length(self, other)
  let result = longer.clone()
  for i = 0; i < shorter.set.length(); i = i + 1 {
    result.set[i] = shorter.set[i] ^ longer.set[i]
  }
  result
}

///|
/// Complement computes the (local) complement of a bitset (up to length bits)
pub fn complement(self : BitSet) -> BitSet {
  let result = BitSet::new(self.length)
  for i = 0; i < self.set.length(); i = i + 1 {
    result.set[i] = self.set[i].lnot()
  }
  result.clean_last_word()
  result
}

///|
/// Clean last word by setting unused bits to 0
fn clean_last_word(self : BitSet) -> Unit {
  if not(self.is_len_exact_multiple()) {
    let last_idx = self.set.length() - 1
    if last_idx >= 0 {
      self.set[last_idx] = self.set[last_idx] &
        (AllBits >> (WordSize - words_index(self.length)).reinterpret_as_int())
    }
  }
}

///|
/// Check if the length is an exact multiple of word sizes
fn is_len_exact_multiple(self : BitSet) -> Bool {
  words_index(self.length) == 0
}

///|
/// In-place intersection operation
pub fn in_place_intersection_fixed(self : BitSet, other : BitSet) -> Unit {
  let l = other.word_count().min(self.word_count())
  for i = 0; i < l; i = i + 1 {
    self.set[i] = self.set[i] & other.set[i]
  }
  // Clear remaining words
  for i = l; i < self.set.length(); i = i + 1 {
    self.set[i] = 0UL
  }
  if other.length > 0 && other.length - 1 >= self.length {
    self.extend_set(other.length - 1) catch {
      _ => ()
    }
  }
}

///|
/// In-place union operation
pub fn in_place_union(self : BitSet, other : BitSet) -> Unit {
  let l = other.word_count().min(self.word_count())
  if other.length > 0 && other.length - 1 >= self.length {
    self.extend_set(other.length - 1) catch {
      _ => ()
    }
  }
  for i = 0; i < l; i = i + 1 {
    self.set[i] = self.set[i] | other.set[i]
  }
  // Copy remaining words from other if it's longer
  if other.set.length() > l {
    for i = l; i < other.set.length(); i = i + 1 {
      if i < self.set.length() {
        self.set[i] = other.set[i]
      }
    }
  }
}

///|
/// In-place difference operation
pub fn in_place_difference(self : BitSet, other : BitSet) -> Unit {
  let l = other.word_count().min(self.word_count())
  for i = 0; i < l; i = i + 1 {
    self.set[i] = self.set[i] & other.set[i].lnot()
  }
}

///|
/// In-place symmetric difference operation
pub fn in_place_symmetric_difference(self : BitSet, other : BitSet) -> Unit {
  let l = other.word_count().min(self.word_count())
  if other.length > 0 && other.length - 1 >= self.length {
    self.extend_set(other.length - 1) catch {
      _ => ()
    }
  }
  for i = 0; i < l; i = i + 1 {
    self.set[i] = self.set[i] ^ other.set[i]
  }
  // Copy remaining words from other if it's longer
  if other.set.length() > l {
    for i = l; i < other.set.length(); i = i + 1 {
      if i < self.set.length() {
        self.set[i] = other.set[i]
      }
    }
  }
}

///|
/// Count the number of set bits in a UInt64 (population count)
fn popcount64(x : UInt64) -> Int {
  // Brian Kernighan's algorithm
  let mut count = 0
  let mut n = x
  while n != 0UL {
    n = n & (n - 1UL) // Clear the lowest set bit
    count = count + 1
  }
  count
}

///|
/// Count the number of set bits in a slice of UInt64
fn popcount_slice(slice : Array[UInt64]) -> UInt64 {
  let mut cnt = 0UL
  for i = 0; i < slice.length(); i = i + 1 {
    cnt = cnt + popcount64(slice[i]).to_uint64()
  }
  cnt
}

///|
/// Count (number of set bits). Also known as "popcount" or "population count".
pub fn count(self : BitSet) -> UInt {
  if self.set.length() > 0 {
    popcount_slice(self.set).to_uint()
  } else {
    0
  }
}

///|
/// Clear all bits in the BitSet. It does not free the memory.
/// Use cascading operator for chaining: `bs..clear_all()..set(10)`
pub fn clear_all(self : BitSet) -> Unit {
  for i = 0; i < self.set.length(); i = i + 1 {
    self.set[i] = 0UL
  }
}

///|
/// Set all bits in the BitSet
/// Use cascading operator for chaining: `bs..set_all()..clear(10)`
pub fn set_all(self : BitSet) -> Unit {
  for i = 0; i < self.set.length(); i = i + 1 {
    self.set[i] = AllBits
  }
  self.clean_last_word()
}

///|
/// All returns true if all bits are set, false otherwise. Returns true for empty sets.
pub fn all(self : BitSet) -> Bool {
  self.count() == self.length
}

///|
/// None returns true if no bit is set, false otherwise. Returns true for empty sets.
pub fn none(self : BitSet) -> Bool {
  for i = 0; i < self.set.length(); i = i + 1 {
    if self.set[i] > 0UL {
      return false
    }
  }
  true
}

///|
/// Any returns true if any bit is set, false otherwise
pub fn any(self : BitSet) -> Bool {
  not(self.none())
}

///|
/// Equal tests the equivalence of two BitSets.
/// False if they are of different sizes, otherwise true only if all the same bits are set
pub fn equal(self : BitSet, other : BitSet) -> Bool {
  if self.length != other.length {
    false
  } else if self.length == 0 {
    true
  } else {
    let wn = self.word_count()
    if wn <= 0 {
      true
    } else {
      let mut equal = true
      for p = 0; p < wn && equal; p = p + 1 {
        if p < other.set.length() && p < self.set.length() {
          if other.set[p] != self.set[p] {
            equal = false
          }
        } else {
          equal = false
        }
      }
      equal
    }
  }
}

///|
/// Check if this BitSet is a superset of the other set
pub fn is_superset(self : BitSet, other : BitSet) -> Bool {
  let l = other.word_count().min(self.word_count())
  let mut is_super = true
  for i = 0; i < l && is_super; i = i + 1 {
    if i < self.set.length() && i < other.set.length() {
      if (self.set[i] & other.set[i]) != other.set[i] {
        is_super = false
      }
    }
  }
  // Check if remaining words in other are all zero
  if is_super {
    for i = l; i < other.set.length() && is_super; i = i + 1 {
      if other.set[i] != 0UL {
        is_super = false
      }
    }
  }
  is_super
}

///|
/// Check if this BitSet is a strict superset of the other set
pub fn is_strict_superset(self : BitSet, other : BitSet) -> Bool {
  self.count() > other.count() && self.is_superset(other)
}

///|
/// Count trailing zeros in a UInt64 (similar to bits.TrailingZeros64 in Go)
fn trailing_zeros64(x : UInt64) -> Int {
  if x == 0UL {
    64
  } else {
    let mut count = 0
    let mut n = x
    while (n & 1UL) == 0UL {
      count = count + 1
      n = n >> 1
    }
    count
  }
}

///|
/// Count leading zeros in a UInt64
fn leading_zeros64(x : UInt64) -> Int {
  if x == 0UL {
    64
  } else {
    let mut count = 0
    let mut n = x
    while (n & 0x8000000000000000UL) == 0UL {
      count = count + 1
      n = n << 1
    }
    count
  }
}

///|
/// Calculate the bit length of a UInt64 (number of bits needed to represent the value)
fn bit_len64(x : UInt64) -> Int {
  64 - leading_zeros64(x)
}

///|
/// Find the next set bit from the specified index, including possibly the current index
/// Returns (index, found) where found is true if a set bit was found
pub fn next_set(self : BitSet, i : UInt) -> (UInt, Bool) {
  let x = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  if x >= self.set.length() {
    (0, false)
  } else {
    // Process first (partial) word
    let word = self.set[x] >> words_index(i).reinterpret_as_int()
    if word != 0UL {
      (i + trailing_zeros64(word).reinterpret_as_uint(), true)
    } else {
      // Process the following full words until next bit is set
      let mut found = false
      let mut result = 0U
      for idx = x + 1; idx < self.set.length() && not(found); idx = idx + 1 {
        let word = self.set[idx]
        if word != 0UL {
          result = ((idx << Log2WordSize.reinterpret_as_int()) +
          trailing_zeros64(word)).reinterpret_as_uint()
          found = true
        }
      }
      (result, found)
    }
  }
}

///|
/// Find the next clear bit from the specified index, including possibly the current index
/// Returns (index, found) where found is true if a clear bit was found
pub fn next_clear(self : BitSet, i : UInt) -> (UInt, Bool) {
  let x = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  if x >= self.set.length() {
    (0, false)
  } else {
    // Process first (maybe partial) word
    let word = self.set[x]
    let shifted_word = word >> words_index(i).reinterpret_as_int()
    let word_all = AllBits >> words_index(i).reinterpret_as_int()
    let index = i + trailing_zeros64(shifted_word.lnot()).reinterpret_as_uint()
    if shifted_word != word_all && index < self.length {
      (index, true)
    } else {
      // Process the following full words until next bit is cleared
      let mut found = false
      let mut result = 0U
      for idx = x + 1; idx < self.set.length() && not(found); idx = idx + 1 {
        let word = self.set[idx]
        if word != AllBits {
          let index = (idx * WordSize.reinterpret_as_int() +
          trailing_zeros64(word.lnot())).reinterpret_as_uint()
          if index < self.length {
            result = index
            found = true
          }
        }
      }
      (result, found)
    }
  }
}

///|
/// Find the previous set bit from the specified index, including possibly the current index
/// Returns (index, found) where found is true if a set bit was found
pub fn previous_set_fixed(self : BitSet, i : UInt) -> (UInt, Bool) {
  let x = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  if x >= self.set.length() {
    (0, false)
  } else {
    let word = self.set[x]
    // Clear the bits above the index
    let masked_word = word &
      ((1UL << (words_index(i) + 1).reinterpret_as_int()) - 1UL)
    if masked_word != 0UL {
      (
        (x << Log2WordSize.reinterpret_as_int()).reinterpret_as_uint() +
        bit_len64(masked_word).reinterpret_as_uint() -
        1,
        true,
      )
    } else {
      // Search in previous words
      let mut found = false
      let mut result = 0U
      for idx = x - 1; idx >= 0 && not(found); idx = idx - 1 {
        let word = self.set[idx]
        if word != 0UL {
          result = (idx << Log2WordSize.reinterpret_as_int()).reinterpret_as_uint() +
            bit_len64(word).reinterpret_as_uint() -
            1
          found = true
        }
      }
      (result, found)
    }
  }
}

///|
/// Find the previous clear bit from the specified index, including possibly the current index
/// Returns (index, found) where found is true if a clear bit was found
pub fn previous_clear(self : BitSet, i : UInt) -> (UInt, Bool) {
  let x = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  if x >= self.set.length() {
    (0, false)
  } else {
    let word = self.set[x]
    // Flip all bits and find the highest one bit
    let flipped_word = word.lnot()
    // Clear the bits above the index
    let masked_word = flipped_word &
      ((1UL << (words_index(i) + 1).reinterpret_as_int()) - 1UL)
    if masked_word != 0UL {
      (
        (x << Log2WordSize.reinterpret_as_int()).reinterpret_as_uint() +
        bit_len64(masked_word).reinterpret_as_uint() -
        1,
        true,
      )
    } else {
      // Search in previous words
      let mut found = false
      let mut result = 0U
      for idx = x - 1; idx >= 0 && not(found); idx = idx - 1 {
        let word = self.set[idx].lnot()
        if word != 0UL {
          result = (idx << Log2WordSize.reinterpret_as_int()).reinterpret_as_uint() +
            bit_len64(word).reinterpret_as_uint() -
            1
          found = true
        }
      }
      (result, found)
    }
  }
}

///|
/// Flip a range of bits in [start, end).
/// Warning: using a very large value for 'end' may lead to a memory shortage and a panic.
/// Use cascading operator for chaining: `bs..flip_range(10, 20)..set(30)`
pub fn flip_range(self : BitSet, start : UInt, end : UInt) -> Unit raise {
  if start >= end {
    return
  }
  if end - 1 >= self.length {
    self.extend_set(end - 1)
  }
  let start_word = (start >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  let end_word = (end >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()

  // Handle startWord special, gets reflipped in range loop
  self.set[start_word] = self.set[start_word] ^
    (AllBits << words_index(start).reinterpret_as_int()).lnot()
  for idx = start_word; idx < end_word; idx = idx + 1 {
    self.set[idx] = self.set[idx].lnot()
  }

  // Handle endWord special
  let end_mask_idx = words_index(end.lnot() + 1)
  if end_mask_idx != 0 {
    self.set[end_word] = self.set[end_word] ^
      (AllBits >> end_mask_idx.reinterpret_as_int())
  }
}

///|
/// Shrink BitSet so that the provided value is the last possible set value.
/// It clears all bits > the provided index and reduces the size and length of the set.
/// Use cascading operator for chaining: `bs..shrink(100)..set(50)`
pub fn shrink(self : BitSet, last_bit_index : UInt) -> Unit {
  let length = last_bit_index + 1
  let idx = words_needed(length)
  if idx > self.set.length() {
    return
  }
  let shrunk = Array::make(idx, 0UL)
  for i = 0; i < idx.min(self.set.length()); i = i + 1 {
    shrunk[i] = self.set[i]
  }
  self.set = shrunk
  self.length = length
  let last_word_used_bits = length % WordSize
  if last_word_used_bits != 0 && idx > 0 {
    self.set[idx - 1] = self.set[idx - 1] &
      (
        AllBits >>
        (WordSize - words_index(last_word_used_bits)).reinterpret_as_int()
      )
  }
}

///|
/// Compact shrinks BitSet to preserve all set bits while minimizing memory usage.
/// Use cascading operator for chaining: `bs..compact()..set(50)`
pub fn compact(self : BitSet) -> Unit {
  let mut idx = self.set.length() - 1
  while idx >= 0 && self.set[idx] == 0UL {
    idx = idx - 1
  }
  let new_length = ((idx + 1) << Log2WordSize.reinterpret_as_int()).reinterpret_as_uint()
  if new_length >= self.length {
    return // nothing to do
  }
  if new_length > 0 {
    self.shrink(new_length - 1)
  } else {
    // We preserve one word
    self.shrink(63)
  }
}

///|
/// Copy into a destination BitSet using the Go array copy semantics.
/// Returns the number of bits copied in the destination BitSet.
pub fn copy_to(self : BitSet, dest : BitSet) -> UInt {
  if dest.set.length() == 0 {
    return 0
  }
  let count = if dest.length < self.length { dest.length } else { self.length }
  for i = 0; i < self.set.length().min(dest.set.length()); i = i + 1 {
    dest.set[i] = self.set[i]
  }

  // Clean the last word to maintain invariant
  dest.clean_last_word()
  count
}

///|
/// Copy the entire BitSet to a destination BitSet, allocating memory if necessary.
pub fn copy_full(self : BitSet, dest : BitSet) -> Unit {
  dest.length = self.length
  if self.set.length() == 0 {
    dest.set = []
  } else {
    dest.set = Array::make(self.set.length(), 0UL)
    for i = 0; i < self.set.length(); i = i + 1 {
      dest.set[i] = self.set[i]
    }
  }
}

///|
/// Get a word (64 bits) at the specified bit position
pub fn get_word64_at_bit(self : BitSet, i : UInt) -> UInt64 {
  let first_word_index = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  let sub_word_index = words_index(i)

  // The word that the index falls within, shifted so the index is at bit 0
  let first_word = if first_word_index < self.set.length() {
    self.set[first_word_index] >> sub_word_index.reinterpret_as_int()
  } else {
    0UL
  }

  // The next word, masked to only include the necessary bits and shifted to cover the
  // top of the word
  let second_word = if first_word_index + 1 < self.set.length() {
    self.set[first_word_index + 1] <<
    (WordSize - sub_word_index).reinterpret_as_int()
  } else {
    0UL
  }
  first_word | second_word
}

///|
/// Create a string representation of the BitSet (for debugging, not serialization)
pub fn to_string(self : BitSet) -> String {
  let mut result = "{"
  let mut counter = 0
  let mut i = 0U
  let mut found = true
  while found && counter <= 0x40000 { // Avoid exhausting memory
    let (next_i, is_found) = self.next_set(i)
    if is_found {
      counter = counter + 1
      i = next_i
      if counter > 1 {
        result = result + ","
      }
      result = result + i.to_string()
      i = i + 1
      found = true
    } else {
      found = false
    }
  }
  if counter > 0x40000 {
    result = result + "..."
  }
  result + "}"
}

///|
/// Count bits set between [from, to). Returns 0 if from >= to.
pub fn ones_between(self : BitSet, from : UInt, to : UInt) -> UInt {
  if from >= to {
    return 0
  }

  // Calculate indices and masks for the starting and ending words
  let start_word = (from >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  let end_word = (to >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()
  let start_offset = words_index(from)
  let end_offset = words_index(to)

  // Case 1: Bits lie within a single word
  if start_word == end_word && start_word < self.set.length() {
    // Create mask for bits between from and to
    let mask = ((1UL << end_offset.reinterpret_as_int()) - 1UL) &
      ((1UL << start_offset.reinterpret_as_int()) - 1UL).lnot()
    return popcount64(self.set[start_word] & mask).reinterpret_as_uint()
  }
  let mut count = 0U

  // Case 2: Bits span multiple words
  // 2a: Count bits in first word (from start_offset to end of word)
  if start_word < self.set.length() {
    let start_mask = (1UL << start_offset.reinterpret_as_int()).lnot().lnot() // Mask for bits >= start_offset
    count = count +
      popcount64(self.set[start_word] & start_mask).reinterpret_as_uint()
  }

  // 2b: Count all bits in complete words between start and end
  if end_word > start_word + 1 {
    for idx = start_word + 1
        idx < end_word && idx < self.set.length()
        idx = idx + 1 {
      count = count + popcount64(self.set[idx]).reinterpret_as_uint()
    }
  }

  // 2c: Count bits in last word (from start of word to end_offset)
  if end_offset > 0 && end_word < self.set.length() {
    let end_mask = (1UL << end_offset.reinterpret_as_int()) - 1UL // Mask for bits < end_offset
    count = count +
      popcount64(self.set[end_word] & end_mask).reinterpret_as_uint()
  }
  count
}

///|
/// Delete a bit at the given index position, shifting all bits to the right of it left by 1
/// Use cascading operator for chaining: `bs..delete_at(10)..set(20)`
pub fn delete_at(self : BitSet, i : UInt) -> Unit {
  if i >= self.length {
    return
  }

  // the index of the slice element where we'll delete a bit
  let delete_at_element = (i >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()

  // generate a mask for the data that needs to be shifted right within that slice element
  let data_mask = ((1UL << words_index(i).reinterpret_as_int()) - 1UL).lnot()

  // extract the data that we'll shift right from the slice element
  let data = self.set[delete_at_element] & data_mask

  // set the masked area to 0 while leaving the rest as it is
  self.set[delete_at_element] = self.set[delete_at_element] & data_mask.lnot()

  // shift the previously extracted data to the right and then set it in the previously masked area
  self.set[delete_at_element] = self.set[delete_at_element] |
    ((data >> 1) & data_mask)

  // loop over all the consecutive slice elements to copy each lowest bit into the highest position
  // of the previous element, then shift the entire content to the right by 1
  for idx = delete_at_element + 1; idx < self.set.length(); idx = idx + 1 {
    self.set[idx - 1] = self.set[idx - 1] | ((self.set[idx] & 1UL) << 63)
    self.set[idx] = self.set[idx] >> 1
  }
  self.length = self.length - 1
}

///|
/// Insert a bit at the given index, shifting all bits at and after that position to the right by 1
/// Use cascading operator for chaining: `bs..insert_at(10)..set(20)`
pub fn insert_at(self : BitSet, idx : UInt) -> Unit {
  let insert_at_element = (idx >> Log2WordSize.reinterpret_as_int()).reinterpret_as_int()

  // if length of set is a multiple of word_size we need to allocate more space first
  if self.is_len_exact_multiple() {
    self.set.push(0UL)
  }

  // Shift elements from the end to the insertion point
  for i = self.set.length() - 1; i > insert_at_element; i = i - 1 {
    // all elements above the position where we want to insert can simply be shifted
    self.set[i] = self.set[i] << 1

    // we take the most significant bit of the previous element and set it as
    // the least significant bit of the current element
    self.set[i] = self.set[i] | ((self.set[i - 1] & 0x8000000000000000UL) >> 63)
  }

  // generate a mask to extract the data that we need to shift left within the element where we insert a bit
  let data_mask = (1UL << words_index(idx).reinterpret_as_int()) - 1UL

  // extract that data that we'll shift
  let data = self.set[insert_at_element] & data_mask.lnot()

  // set the positions of the data mask to 0 in the element where we insert
  self.set[insert_at_element] = self.set[insert_at_element] & data_mask

  // shift data mask to the left and insert its data to the slice element
  self.set[insert_at_element] = self.set[insert_at_element] | (data << 1)

  // add 1 to length of BitSet
  self.length = self.length + 1
}
