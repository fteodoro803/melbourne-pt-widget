extension ListUtils<E> on List<E> {

  /// Checks if this list shared elements with [otherList].
  bool hasSharedItems(List<E> otherList) {
    // Convert to set for efficiency
    Set<E> otherSet = Set.from(otherList);
    return any((element) => otherSet.contains(element));
  }

  /// Returns a list containing all elements that exist in both this list and [otherList].
  List<E> sharedItems(List<E> otherList) {
    return this.fold([], (accumulator, curr) {
      if (otherList.contains(curr)) {
        accumulator.add(curr);
      }
      return accumulator;
    });
  }

  /// Returns the longest continuous sublist starting from [index] where all elements
  /// are also present in [otherList].
  List<E> sharedSublist(List<E> otherList, int index) {
    // Edge cases
    if (index > length || index < 0|| isEmpty || otherList.isEmpty || this.hasSharedItems(otherList) == false) {
      return [];
    }

    // Convert otherList to Set for efficiency
    Set<E> otherSet = Set.from(otherList);

    // 1. Check if selected element in this list is in the other list
    if (!otherSet.contains(this[index])) {
      return [];
    }

    // Assumption: All elements in a list is unique
    // todo: what if there's one element in the list? Or what if the index is at the start/end of the list
    int minIndex = index;
    int maxIndex = index;

    // 2. Check left side
    for (int i=index; i>0; i--) {
      // print("${this[i]} in $otherSet: ${otherSet.contains(this[i])}");
      if (otherSet.contains(this[i])) {
        // print("minIndex = $i");
        minIndex = i;
      } else {
        break;
      }
    }

    // 3. Check right side
    for (int i=index; i<length; i++) {
      // print("${this[i]} in $otherSet: ${otherSet.contains(this[i])}");
      if (otherSet.contains(this[i])) {
        // print("maxIndex = $i");
        maxIndex = i;
      } else {
        break;
      }
    }

    // 4. Create a sublist of this list, from minIndex to maxIndex
    List<E> sublist = this.sublist(minIndex, maxIndex+1);
    // print("( list_extensions.dart -> sharedSublist ) -- Sublist($minIndex, $maxIndex) of $this:\n\t$sublist");
    
    return sublist;
  }
}