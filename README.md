# triple_dropdown_search

Single and multiple customer selection with State and Township filters. Popup is anchored to the field.

## Install locally

```yaml
dependencies:
  triple_dropdown_search:
    path: packages/triple_dropdown_search
```

## Multi-selection

```dart
TripleDropdownSearch<StateModel, TownshipModel, CustomerModel>.multiSelection(
  selectedItems: controller.selectedCustomers,
  onMultiSelected: (customers) => controller.selectedCustomers = customers,
  multiValidator: (customers) => customers == null || customers.isEmpty ? 'Choose customers' : null,
  loadT: (keyword) async => controller.stateList,
  loadS: (keyword, state) async => controller.townshipList.where((x) => state == null || x.state?.id == state.id).toList(),
  loadU: (keyword, state, township, pageNo) async => controller.customerList.where((x) =>
    (state == null || x.state?.id == state.id) &&
    (township == null || x.township?.id == township.id) &&
    (x.name ?? '').toLowerCase().contains(keyword.toLowerCase())).toList(),
  tAsString: (x) => x.name ?? '',
  sAsString: (x) => x.name ?? '',
  uAsString: (x) => x.name ?? '',
  compareFn: (a, b) => a.id == b.id,
  allTText: 'All states', allSText: 'All townships', allCText: 'All customers',
  searchTText: 'Search state', searchSText: 'Search township', searchCText: 'Search customer',
)
```

## Single selection

Use `TripleDropdownSearch<T,S,U>(selectedItem: ..., onSelected: ..., ...)` with the same loaders and label callbacks.

Multi-selection is staged in the popup until **Done** is pressed. Tapping outside cancels uncommitted selections. Items remain checked while searching and paging. State/Township filters do not clear already checked customers. `compareFn` is used for equality.

**Before publishing:** replace repository URL, add LICENSE, run `flutter analyze`, `flutter test`, and `dart pub publish --dry-run`. Flutter SDK is not available in this build environment.
