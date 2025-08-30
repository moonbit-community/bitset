///|
test "basic bitset creation and operations" {
  let bs = BitSet::new(100)
  inspect(bs.len(), content="100")
  let empty = BitSet::empty()
  inspect(empty.len(), content="0")

  // Test setting and testing bits
  bs..set(10)..set(20)..set(30) catch {
    _ => ()
  }
  inspect(bs.test_bit(10), content="true")
  inspect(bs.test_bit(20), content="true")
  inspect(bs.test_bit(30), content="true")
  inspect(bs.test_bit(15), content="false")

  // Test clearing bits
  bs..clear(20)
  inspect(bs.test_bit(20), content="false")

  // Test length after setting high bit
  inspect(bs.len(), content="100")
}

///|
test "bitwise operations" {
  let bs1 = BitSet::new(64)
  let bs2 = BitSet::new(64)
  try {
    bs1..set(1)..set(3)..set(5)
    bs2..set(2)..set(3)..set(6)
  } catch {
    _ => ()
  }

  // Test intersection
  let intersection = bs1.intersection(bs2)
  inspect(intersection.test_bit(1), content="false")
  inspect(intersection.test_bit(2), content="false")
  inspect(intersection.test_bit(3), content="true")
  inspect(intersection.test_bit(5), content="false")
  inspect(intersection.test_bit(6), content="false")

  // Test union
  let union = bs1.union(bs2)
  inspect(union.test_bit(1), content="true")
  inspect(union.test_bit(2), content="true")
  inspect(union.test_bit(3), content="true")
  inspect(union.test_bit(5), content="true")
  inspect(union.test_bit(6), content="true")

  // Test difference
  let diff = bs1.difference(bs2)
  inspect(diff.test_bit(1), content="true")
  inspect(diff.test_bit(2), content="false")
  inspect(diff.test_bit(3), content="false")
  inspect(diff.test_bit(5), content="true")
  inspect(diff.test_bit(6), content="false")
}

///|
test "utility functions" {
  let bs = BitSet::new(64)
  bs..set(1)..set(3)..set(5)..set(7) catch {
    _ => ()
  }

  // Test count
  inspect(bs.count(), content="4")

  // Test any/all/none
  inspect(bs.any(), content="true")
  inspect(bs.all(), content="false")
  inspect(bs.none(), content="false")
  let empty = BitSet::empty()
  inspect(empty.any(), content="false")
  inspect(empty.none(), content="true")
  inspect(empty.all(), content="true")

  // Test equality
  let bs2 = BitSet::new(64)
  bs2..set(1)..set(3)..set(5)..set(7) catch {
    _ => ()
  }
  inspect(bs.equal(bs2), content="true")
  bs2..set(9) catch {
    _ => ()
  }
  inspect(bs.equal(bs2), content="false")
}

///|
test "iteration methods" {
  let bs = BitSet::new(100)
  bs..set(5)..set(15)..set(25)..set(35) catch {
    _ => ()
  }

  // Test next_set
  let (next, found) = bs.next_set(0)
  inspect(found, content="true")
  inspect(next, content="5")
  let (next2, found2) = bs.next_set(6)
  inspect(found2, content="true")
  inspect(next2, content="15")
  let (_, found3) = bs.next_set(36)
  inspect(found3, content="false")

  // Test previous_set_fixed
  let (prev, found_prev) = bs.previous_set_fixed(30)
  inspect(found_prev, content="true")
  inspect(prev, content="25")
}

///|
test "range operations" {
  let bs = BitSet::new(100)

  // Test flip_range
  bs..flip_range(10, 20) catch {
    _ => ()
  }
  inspect(bs.test_bit(9), content="false")
  inspect(bs.test_bit(10), content="true")
  inspect(bs.test_bit(15), content="true")
  inspect(bs.test_bit(19), content="true")
  inspect(bs.test_bit(20), content="false")

  // Test ones_between
  let count = bs.ones_between(10, 20)
  inspect(count, content="10")
}

///|
test "clone and copy operations" {
  let bs1 = BitSet::new(64)
  bs1..set(10)..set(20)..set(30) catch {
    _ => ()
  }

  // Test clone
  let bs2 = bs1.clone()
  inspect(bs2.test_bit(10), content="true")
  inspect(bs2.test_bit(20), content="true")
  inspect(bs2.test_bit(30), content="true")
  inspect(bs2.len(), content="64")

  // Modify original, clone should be unaffected
  bs1..clear(20)
  inspect(bs1.test_bit(20), content="false")
  inspect(bs2.test_bit(20), content="true")
}

///|
test "complement operation" {
  let bs = BitSet::new(8)
  bs..set(1)..set(3)..set(5) catch {
    _ => ()
  }
  let comp = bs.complement()
  inspect(comp.test_bit(0), content="true")
  inspect(comp.test_bit(1), content="false")
  inspect(comp.test_bit(2), content="true")
  inspect(comp.test_bit(3), content="false")
  inspect(comp.test_bit(4), content="true")
  inspect(comp.test_bit(5), content="false")
  inspect(comp.test_bit(6), content="true")
  inspect(comp.test_bit(7), content="true")
}

///|
test "set operations with cascading" {
  let bs = BitSet::new(64)
  // Test cascading
  bs..set(10)..set(20)..flip(30) catch {
    _ => ()
  }
  inspect(bs.test_bit(10), content="true")
  inspect(bs.test_bit(20), content="true")
  inspect(bs.test_bit(30), content="true")

  // Test set_to
  bs..set_to(40, true)..set_to(50, false) catch {
    _ => ()
  }
  inspect(bs.test_bit(40), content="true")
  inspect(bs.test_bit(50), content="false")
}

///|
test "string representation" {
  let empty = BitSet::empty()
  inspect(empty.to_string(), content="{}")
  let bs = BitSet::new(64)
  bs..set(1)..set(3)..set(5) catch {
    _ => ()
  }
  inspect(bs.to_string(), content="{1,3,5}")
}
