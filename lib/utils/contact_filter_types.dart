enum ContactSortOption { lastSeen, recentMessages, name }

enum ContactTypeFilter { all, favorites, users, repeaters, rooms }

enum ContactSourceFilter { all, saved, discovered }

/// How many repeaters a repeater's last advert passed on its way here.
enum RepeaterHopFilter {
  any,
  direct,
  one,
  two,
  threeOrMore;

  /// A repeater never heard advertising has no count, and matches only [any].
  bool matches(int? hops) => switch (this) {
        any => true,
        direct => hops == 0,
        one => hops == 1,
        two => hops == 2,
        threeOrMore => hops != null && hops >= 3,
      };
}
