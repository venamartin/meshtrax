/// [hops] is offered for repeaters only: how many repeaters the last advert
/// passed on its way here, fewest first.
enum ContactSortOption { lastSeen, recentMessages, name, hops }

enum ContactTypeFilter { all, favorites, users, repeaters, rooms }

enum ContactSourceFilter { all, saved, discovered }

/// How recently a repeater must have been heard to stay in the list; it
/// goes with any sort and the Favorites filter. Two days, not one: a
/// repeater adverts every 47 hours by default.
enum HeardWithin {
  anyTime(null),
  hour(Duration(hours: 1)),
  twoDays(Duration(hours: 48)),
  week(Duration(days: 7));

  const HeardWithin(this.window);

  final Duration? window;

  /// Whether a contact last heard at [lastSeen] stays in the list at [now].
  bool keeps(DateTime lastSeen, DateTime now) {
    final w = window;
    return w == null || now.difference(lastSeen) <= w;
  }
}
