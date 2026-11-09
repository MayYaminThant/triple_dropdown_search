import 'dart:async';

import 'package:flutter/material.dart';

typedef TLoader<T> = Future<List<T>> Function(String keyword);
typedef SLoader<T, S> = Future<List<S>> Function(String keyword, T? t);
typedef ULoader<T, S, U> = Future<List<U>> Function(
    String keyword, T? t, S? s, int pageNo);

/// One field in the form. T, S and U search live in an
/// anchored popup attached to the field (not in a modal dialog).
class TripleDropdownSearch<T, S, U> extends StatefulWidget {
  final U? selectedItem;
  final List<U> selectedItems;
  final ValueChanged<List<U>>? onMultiSelected;
  final FormFieldValidator<List<U>>? multiValidator;
  final FormFieldSetter<List<U>>? onMultiSaved;
  final bool isMultiSelect;
  final TLoader<T> loadT;
  final SLoader<T, S> loadS;
  final ULoader<T, S, U> loadU;
  final String Function(T) tAsString;
  final String Function(S) sAsString;
  final String Function(U) uAsString;
  final bool Function(U, U)? compareFn;
  final ValueChanged<U?>? onSelected;
  final Widget Function(BuildContext, U, bool, bool)? itemBuilder;
  final FormFieldValidator<U>? validator;
  final FormFieldSetter<U>? onSaved;
  final bool enable, readOnly, showSearchBox, visibleSuffixProps, showUnderline;
  final EdgeInsetsGeometry? contentPadding;
  final Color popupColor;
  final int debounceMilliseconds, firstPage;
  final double popupMaxHeight, popupMaxWidth;
  final String dropDownHeader;
  final String allTText;
  final String allSText;
  final String allCText;
  final String searchTText;
  final String searchSText;
  final String searchCText;

  const TripleDropdownSearch({
    super.key,
    this.selectedItem,
    this.selectedItems = const [],
    this.onMultiSelected,
    this.multiValidator,
    this.onMultiSaved,
    this.isMultiSelect = false,
    required this.loadT,
    required this.loadS,
    required this.loadU,
    required this.tAsString,
    required this.sAsString,
    required this.uAsString,
    this.compareFn,
    this.onSelected,
    this.itemBuilder,
    this.validator,
    this.onSaved,
    this.enable = true,
    this.readOnly = false,
    this.showSearchBox = true,
    this.visibleSuffixProps = true,
    this.showUnderline = true,
    this.contentPadding,
    this.popupColor = const Color(0xFFFFE7E7),
    this.debounceMilliseconds = 350,
    this.firstPage = 1,
    this.popupMaxHeight = 460,
    this.popupMaxWidth = 600,
    this.dropDownHeader = 'Select',
    required this.allTText,
    required this.allSText,
    required this.allCText,
    required this.searchTText,
    required this.searchSText,
    required this.searchCText,
  });

  const TripleDropdownSearch.multiSelection({
    super.key,
    this.selectedItem,
    this.selectedItems = const [],
    this.onMultiSelected,
    this.multiValidator,
    this.onMultiSaved,
    this.isMultiSelect = true,
    required this.loadT,
    required this.loadS,
    required this.loadU,
    required this.tAsString,
    required this.sAsString,
    required this.uAsString,
    this.compareFn,
    this.onSelected,
    this.itemBuilder,
    this.validator,
    this.onSaved,
    this.enable = true,
    this.readOnly = false,
    this.showSearchBox = true,
    this.visibleSuffixProps = true,
    this.showUnderline = true,
    this.contentPadding,
    this.popupColor = const Color(0xFFFFE7E7),
    this.debounceMilliseconds = 350,
    this.firstPage = 1,
    this.popupMaxHeight = 460,
    this.popupMaxWidth = 600,
    this.dropDownHeader = 'Select',
    required this.allTText,
    required this.allSText,
    required this.allCText,
    required this.searchTText,
    required this.searchSText,
    required this.searchCText,
  });

  @override
  State<TripleDropdownSearch<T, S, U>> createState() =>
      _DropdownState<T, S, U>();
}

class _DropdownState<T, S, U> extends State<TripleDropdownSearch<T, S, U>> {
  final _link = LayerLink();
  final _fieldKey = GlobalKey<FormFieldState<U>>();
  final _multiFieldKey = GlobalKey<FormFieldState<List<U>>>();
  List<U> _selectedMany = [];
  OverlayEntry? _entry;
  U? _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.selectedItem;
    _selectedMany = List<U>.of(widget.selectedItems);
  }

  @override
  void didUpdateWidget(covariant TripleDropdownSearch<T, S, U> old) {
    super.didUpdateWidget(old);
    if (widget.isMultiSelect &&
        !identical(old.selectedItems, widget.selectedItems)) {
      _selectedMany = List<U>.of(widget.selectedItems);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _multiFieldKey.currentState?.didChange(List<U>.of(_selectedMany));
        }
      });
    }
    if (old.selectedItem != widget.selectedItem) {
      _selected = widget.selectedItem;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fieldKey.currentState?.didChange(_selected);
      });
    }
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _close() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  void _open() {
    if (_entry != null) {
      _close();
      return;
    }
    final render = context.findRenderObject() as RenderBox;
    final origin = render.localToGlobal(Offset.zero);
    final size = render.size;
    final screen = MediaQuery.sizeOf(context);
    final bottomSpace = screen.height - origin.dy - size.height;
    final above = bottomSpace < 280 && origin.dy > bottomSpace;
    final available = (above ? origin.dy : bottomSpace) - 12;
    final height = available.clamp(150.0, widget.popupMaxHeight).toDouble();
    final width = size.width.clamp(260.0, widget.popupMaxWidth).toDouble();
    _entry = OverlayEntry(
        builder: (overlayContext) => Stack(children: [
              Positioned.fill(
                  child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _close,
                      child: const SizedBox.expand())),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: above ? Alignment.topLeft : Alignment.bottomLeft,
                followerAnchor:
                    above ? Alignment.bottomLeft : Alignment.topLeft,
                offset: Offset(0, above ? -4 : 4),
                child: Material(
                  elevation: 8,
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8)),
                  color: widget.popupColor,
                  child: SizedBox(
                      width: width,
                      height: height,
                      child: _CustomPopup<T, S, U>(
                        config: widget,
                        selected: _selected,
                        selectedMany: List<U>.of(_selectedMany),
                        onChooseMany: (values) {
                          _close();
                          setState(() => _selectedMany = List<U>.of(values));
                          _multiFieldKey.currentState
                              ?.didChange(List<U>.of(values));
                          widget.onMultiSelected?.call(List<U>.of(values));
                        },
                        onClose: _close,
                        onChoose: (value) {
                          _close();
                          setState(() => _selected = value);
                          _fieldKey.currentState?.didChange(value);
                          widget.onSelected?.call(value);
                        },
                      )),
                ),
              ),
            ]));
    Overlay.of(context).insert(_entry!);
  }

  Widget _buildMulti(BuildContext context) => CompositedTransformTarget(
        link: _link,
        child: FormField<List<U>>(
          key: _multiFieldKey,
          initialValue: List<U>.of(_selectedMany),
          enabled: widget.enable,
          validator: widget.multiValidator,
          onSaved: widget.onMultiSaved,
          builder: (field) => InkWell(
            onTap: !widget.enable || widget.readOnly ? null : _open,
            child: InputDecorator(
              isEmpty: (field.value ?? []).isEmpty,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: widget.contentPadding ??
                    const EdgeInsets.symmetric(vertical: 8),
                border: widget.showUnderline
                    ? const UnderlineInputBorder()
                    : InputBorder.none,
                enabledBorder: widget.showUnderline
                    ? const UnderlineInputBorder()
                    : InputBorder.none,
                suffixIcon: widget.visibleSuffixProps
                    ? const Icon(Icons.arrow_drop_down)
                    : null,
                errorText: field.errorText,
              ),
              child: Text(
                (field.value ?? []).isEmpty
                    ? widget.dropDownHeader
                    : field.value!.map(widget.uAsString).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    color: (field.value ?? []).isEmpty ? Colors.grey : null),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => widget.isMultiSelect
      ? _buildMulti(context)
      : CompositedTransformTarget(
          link: _link,
          child: FormField<U>(
            key: _fieldKey,
            initialValue: _selected,
            enabled: widget.enable,
            validator: widget.validator,
            onSaved: widget.onSaved,
            builder: (field) => InkWell(
              onTap: !widget.enable || widget.readOnly ? null : _open,
              child: InputDecorator(
                isEmpty: field.value == null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: widget.contentPadding ??
                      const EdgeInsets.symmetric(vertical: 8),
                  border: widget.showUnderline
                      ? const UnderlineInputBorder()
                      : InputBorder.none,
                  enabledBorder: widget.showUnderline
                      ? const UnderlineInputBorder()
                      : InputBorder.none,
                  suffixIcon: widget.visibleSuffixProps
                      ? const Icon(Icons.arrow_drop_down)
                      : null,
                  errorText: field.errorText,
                  errorStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold),
                ),
                child: Text(
                    field.value == null
                        ? widget.dropDownHeader
                        : widget.uAsString(field.value as U),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        color: field.value == null ? Colors.grey : null)),
              ),
            ),
          ),
        );
}

class _CustomPopup<T, S, U> extends StatefulWidget {
  final TripleDropdownSearch<T, S, U> config;
  final U? selected;
  final List<U> selectedMany;
  final ValueChanged<List<U>> onChooseMany;
  final ValueChanged<U> onChoose;
  final VoidCallback onClose;
  const _CustomPopup({
    required this.config,
    required this.selected,
    required this.selectedMany,
    required this.onChooseMany,
    required this.onChoose,
    required this.onClose,
  });
  @override
  State<_CustomPopup<T, S, U>> createState() => _CustomPopupState<T, S, U>();
}

class _CustomPopupState<T, S, U> extends State<_CustomPopup<T, S, U>> {
  late List<U> checked;
  T? tObject;
  S? sObject;
  List<T> tList = [];
  List<S> sList = [];
  List<U> uList = [];
  String keyword = '', tKeyword = '', sKeyword = '';
  String? error;
  bool loading = false, loadingFilter = false, hasMore = true;
  int page = 1, requestId = 0, filterId = 0;
  Timer? timer;
  final scroll = ScrollController();
  int view = 0;

  @override
  void initState() {
    super.initState();
    checked = List<U>.of(widget.selectedMany);
    page = widget.config.firstPage;
    _loadUList(reset: true);
    scroll.addListener(() {
      if (view == 0 &&
          scroll.hasClients &&
          scroll.position.extentAfter < 100 &&
          !loading &&
          hasMore) {
        _loadUList();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    scroll.dispose();
    super.dispose();
  }

  void _debounce(VoidCallback fn) {
    timer?.cancel();
    timer =
        Timer(Duration(milliseconds: widget.config.debounceMilliseconds), fn);
  }

  Future<void> _loadUList({bool reset = false}) async {
    if (reset) {
      ++requestId;
      setState(() {
        uList = [];
        page = widget.config.firstPage;
        hasMore = true;
        loading = false;
        error = null;
      });
    }
    if (loading || !hasMore) return;
    final id = requestId;
    final currentPage = page;
    setState(() => loading = true);
    try {
      final result =
          await widget.config.loadU(keyword, tObject, sObject, currentPage);
      if (!mounted || id != requestId) return;
      setState(() {
        uList.addAll(result);
        page++;
        hasMore = result.isNotEmpty;
      });
    } catch (e) {
      if (mounted && id == requestId) setState(() => error = '$e');
    } finally {
      if (mounted && id == requestId) setState(() => loading = false);
    }
  }

  Future<void> _loadFilter() async {
    final id = ++filterId;
    final which = view;
    setState(() {
      loadingFilter = true;
      error = null;
    });
    try {
      if (which == 1) {
        final data = await widget.config.loadT(tKeyword);
        if (mounted && id == filterId && view == which) {
          setState(() => tList = data);
        }
      } else if (which == 2) {
        final data = await widget.config.loadS(sKeyword, tObject);
        if (mounted && id == filterId && view == which) {
          setState(() => sList = data);
        }
      }
    } catch (e) {
      if (mounted && id == filterId) setState(() => error = '$e');
    } finally {
      if (mounted && id == filterId) setState(() => loadingFilter = false);
    }
  }

  void _switch(int next) {
    timer?.cancel();
    ++filterId;
    setState(() {
      view = next;
      error = null;
      loadingFilter = false;
    });
    if (next != 0) _loadFilter();
  }

  bool _isChecked(U value) => checked.any(
      (item) => widget.config.compareFn?.call(item, value) ?? item == value);

  void _toggle(U value) {
    setState(() {
      checked = List<U>.of(checked);
      if (_isChecked(value)) {
        checked.removeWhere((item) =>
            widget.config.compareFn?.call(item, value) ?? item == value);
      } else {
        checked.add(value);
      }
    });
  }

  void _tChanged(T? value) {
    ++filterId;
    setState(() {
      tObject = value;
      sObject = null;
      view = 0;
      sList = [];
      sKeyword = '';
    });
    _loadUList(reset: true);
  }

  void _sChanged(S? value) {
    ++filterId;
    setState(() {
      sObject = value;
      view = 0;
    });
    _loadUList(reset: true);
  }

  Widget _filterButton(String label, VoidCallback? action) => Expanded(
        child: OutlinedButton(
            onPressed: action,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text(
                    view == 1
                        ? c.searchTText
                        : view == 2
                            ? c.searchSText
                            : c.searchCText,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            if (view != 0)
              IconButton(
                  onPressed: () => _switch(0),
                  icon: const Icon(Icons.arrow_back))
            else
              IconButton(
                  onPressed: widget.onClose, icon: const Icon(Icons.close)),
          ]),
          if (view == 0) ...[
            Row(children: [
              _filterButton(
                  tObject == null ? c.allTText : c.tAsString(tObject as T),
                  () => _switch(1)),
              const SizedBox(width: 6),
              _filterButton(
                  sObject == null ? c.allSText : c.sAsString(sObject as S),
                  tObject == null ? null : () => _switch(2)),
            ]),
            if (tObject != null || sObject != null)
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () => _tChanged(null),
                      child: const Text('Clear filters'))),
            if (c.showSearchBox)
              TextField(
                decoration: InputDecoration(
                    hintText: c.searchCText,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: const OutlineInputBorder()),
                onChanged: (text) {
                  keyword = text;
                  _debounce(() => _loadUList(reset: true));
                },
              ),
          ] else ...[
            TextField(
              decoration: InputDecoration(
                  hintText: view == 1 ? c.searchTText : c.searchSText,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder()),
              onChanged: (text) {
                if (view == 1) {
                  tKeyword = text;
                } else {
                  sKeyword = text;
                }
                ++filterId;
                _debounce(_loadFilter);
              },
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                    onPressed: () =>
                        view == 1 ? _tChanged(null) : _sChanged(null),
                    child: Text(view == 1 ? c.allTText : c.allSText))),
          ],
          if (error != null)
            Row(children: [
              Expanded(
                  child: Text(error!,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.red, fontSize: 12))),
              IconButton(
                  onPressed:
                      view == 0 ? () => _loadUList(reset: true) : _loadFilter,
                  icon: const Icon(Icons.refresh)),
            ]),
          Expanded(
              child: view == 0
                  ? ListView.builder(
                      controller: scroll,
                      itemCount: uList.length + (loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == uList.length) {
                          return const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator()));
                        }
                        final u = uList[index];
                        final selected = c.isMultiSelect
                            ? _isChecked(u)
                            : widget.selected != null &&
                                (c.compareFn?.call(u, widget.selected as U) ??
                                    u == widget.selected);
                        return InkWell(
                            onTap: () => c.isMultiSelect
                                ? _toggle(u)
                                : widget.onChoose(u),
                            child: Row(children: [
                              if (c.isMultiSelect)
                                Checkbox(
                                  value: selected,
                                  onChanged: (_) => _toggle(u),
                                ),
                              Expanded(
                                child: c.itemBuilder
                                        ?.call(context, u, false, selected) ??
                                    ListTile(
                                        title: Text(c.uAsString(u)),
                                        selected: selected),
                              ),
                            ]));
                      },
                    )
                  : ListView.builder(
                      itemCount: (view == 1 ? tList.length : sList.length) +
                          (loadingFilter ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (view == 1) {
                          if (index == tList.length) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final value = tList[index];
                          return ListTile(
                              title: Text(c.tAsString(value)),
                              onTap: () => _tChanged(value));
                        }
                        if (index == sList.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final value = sList[index];
                        return ListTile(
                            title: Text(c.sAsString(value)),
                            onTap: () => _sChanged(value));
                      },
                    )),
          if (view == 0 && !loading && uList.isEmpty)
            const Text('No datas found'),
          if (view == 0 && c.isMultiSelect)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => widget.onChooseMany(List<U>.of(checked)),
                child: Text('Done (${checked.length})'),
              ),
            ),
          // if (view == 0 && !loading && hasMore && uList.isNotEmpty)
          //   TextButton(onPressed: _loadUList, child: const Text('Load more')),
        ]));
  }
}
