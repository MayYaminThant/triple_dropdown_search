# Example app

Demonstrates `TripleDropdownSearch<T, S, U>` and `.multiSelection` with:

- State -> Township -> Customer dependent filtering
- Debounced text search in the package popup
- Simulated asynchronous repository methods
- Customer pagination (8 customers per page, starting at page 1)
- Custom customer list tiles, equality comparison, validation, and callbacks
- One anchored dropdown in a `Row` with `Expanded`

## Run

From the package root:

```sh
cd example
flutter pub get
flutter run
```

The example is a minimal Flutter app. If platform folders are needed for your target, run `flutter create .` inside `example` before `flutter run`.

All demo data is generated locally in `lib/main.dart`. Replace `DemoRepository` with your own controller/repository methods. `getCustomer(keywordSearch, stateId, townshipId, pageNo)` must return `Future<List<CustomerModel>>`. Return an empty list when there are no more pages.
