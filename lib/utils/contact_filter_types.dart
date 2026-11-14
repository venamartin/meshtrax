/// [hops] is offered for repeaters only: how many repeaters the last advert
/// passed on its way here, fewest first.
enum ContactSortOption { lastSeen, recentMessages, name, hops }

enum ContactTypeFilter { all, favorites, users, repeaters, rooms }

enum ContactSourceFilter { all, saved, discovered }
