## 1.0.2

### Added
- Added three-level dropdown filtering with T, S, and U selections.
- Added support for single and multiple item selection.
- Added asynchronous data loading for all three dropdown levels.
- Added search functionality for each dropdown level.
- Added paginated loading for the final dropdown list.
- Added customizable item rendering using `itemBuilder`.
- Added form validation and save callbacks for single and multiple selections.
- Added configurable popup colors, maximum height, and maximum width.
- Added customizable dropdown labels and search placeholders.

### Improved
- Improved dropdown popup positioning based on available screen space.
- Improved filtering behavior when selecting or clearing parent filters.
- Improved selected-item synchronization when widget properties change.
- Improved search performance with configurable debounce timing.
- Improved loading indicators and error handling.
- Improved dropdown interaction with read-only and disabled states.

### Fixed
- Fixed potential duplicate selections in multi-selection mode.
- Improved handling of asynchronous requests to prevent outdated results from replacing newer data.
- Improved popup overlay cleanup when closing or disposing the widget.