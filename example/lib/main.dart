import 'package:flutter/material.dart';
import 'package:triple_dropdown_search/triple_dropdown_search.dart';

void main() => runApp(const ExampleApp());

class StateModel {
  final int id;
  final String name;
  const StateModel(this.id, this.name);
}

class TownshipModel {
  final int id;
  final int stateId;
  final String name;
  const TownshipModel(this.id, this.stateId, this.name);
}

class CustomerModel {
  final int id;
  final String name;
  final String address;
  final int stateId;
  final int townshipId;
  const CustomerModel(this.id, this.name, this.address, this.stateId, this.townshipId);
}

/// Fake repository. Replace these methods with your API or SQLite queries.
class DemoRepository {
  static const states = <StateModel>[
    StateModel(1818, 'Yangon'),
    StateModel(1819, 'Mandalay'),
    StateModel(1820, 'Bago'),
  ];

  static const townships = <TownshipModel>[
    TownshipModel(3006, 1818, 'Insein'),
    TownshipModel(3007, 1818, 'Hlaing'),
    TownshipModel(3008, 1818, 'Mayangone'),
    TownshipModel(4001, 1819, 'Chanayethazan'),
    TownshipModel(4002, 1819, 'Aungmyaythazan'),
    TownshipModel(5001, 1820, 'Bago'),
  ];

  final List<CustomerModel> customers = List.generate(72, (index) {
    final township = townships[index % townships.length];
    return CustomerModel(
      index + 1,
      'Customer ${(index + 1).toString().padLeft(3, '0')}',
      'No. ${index + 1}, ${township.name}',
      township.stateId,
      township.id,
    );
  });

  Future<List<StateModel>> getStates(String keyword) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return states.where((s) => s.name.toLowerCase().contains(keyword.toLowerCase())).toList();
  }

  Future<List<TownshipModel>> getTownships(String keyword, StateModel? state) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return townships.where((t) =>
        (state == null || t.stateId == state.id) &&
        t.name.toLowerCase().contains(keyword.toLowerCase())).toList();
  }

  /// Same signature as getCustomer(keywordSearch, stateId, townshipId, pageNo).
  Future<List<CustomerModel>> getCustomer(
    String keywordSearch,
    int? stateId,
    int? townshipId,
    int pageNo,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    const pageSize = 8;
    final filtered = customers.where((c) =>
        (stateId == null || c.stateId == stateId) &&
        (townshipId == null || c.townshipId == townshipId) &&
        (c.name.toLowerCase().contains(keywordSearch.toLowerCase()) ||
            c.address.toLowerCase().contains(keywordSearch.toLowerCase()))).toList();
    final start = (pageNo - 1) * pageSize;
    if (start < 0 || start >= filtered.length) return [];
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Triple Dropdown Search Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFFF44336), useMaterial3: true),
        home: const ExamplePage(),
      );
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final repository = DemoRepository();
  final formKey = GlobalKey<FormState>();
  CustomerModel? selectedCustomer;
  List<CustomerModel> selectedCustomers = [];
  bool enabled = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Triple Dropdown Search')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Single selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                const SizedBox(width: 100, child: Text('Customer')),
                Expanded(child: _singleDropdown()),
              ]),
              const SizedBox(height: 12),
              Text('Selected: ${selectedCustomer?.name ?? 'None'}'),
              const Divider(height: 40),
              const Text('Multi selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                const SizedBox(width: 100, child: Text('Customers')),
                Expanded(child: _multiDropdown()),
              ]),
              const SizedBox(height: 12),
              Text('Selected (${selectedCustomers.length}): ${selectedCustomers.map((c) => c.name).join(', ')}'),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Enable dropdowns'),
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
              ),
              FilledButton(
                onPressed: () {
                  final valid = formKey.currentState?.validate() ?? false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(valid ? 'Form valid' : 'Please select customers')),
                  );
                },
                child: const Text('Validate form'),
              ),
            ],
          ),
        ),
      );

  TripleDropdownSearch<StateModel, TownshipModel, CustomerModel> _singleDropdown() {
    return TripleDropdownSearch<StateModel, TownshipModel, CustomerModel>(
      selectedItem: selectedCustomer,
      enable: enabled,
      loadT: repository.getStates,
      loadS: repository.getTownships,
      loadU: (keyword, state, township, pageNo) => repository.getCustomer(
        keyword, state?.id, township?.id, pageNo,
      ),
      tAsString: (state) => state.name,
      sAsString: (township) => township.name,
      uAsString: (customer) => customer.name,
      compareFn: (a, b) => a.id == b.id,
      onSelected: (value) => setState(() => selectedCustomer = value),
      validator: (value) => value == null ? 'Required choose customer' : null,
      itemBuilder: (context, customer, isDisabled, isSelected) => ListTile(
        title: Text(customer.name),
        subtitle: Text(customer.address),
        selected: isSelected,
      ),
      popupColor: const Color(0xFFFFE7E7),
      dropDownHeader: 'Select customer',
      allTText: 'All States',
      allSText: 'All Townships',
      allCText: 'All Customers',
      searchTText: 'Search State',
      searchSText: 'Search Township',
      searchCText: 'Search Customer',
    );
  }

  TripleDropdownSearch<StateModel, TownshipModel, CustomerModel> _multiDropdown() {
    return TripleDropdownSearch<StateModel, TownshipModel, CustomerModel>.multiSelection(
      selectedItems: selectedCustomers,
      enable: enabled,
      loadT: repository.getStates,
      loadS: repository.getTownships,
      loadU: (keyword, state, township, pageNo) => repository.getCustomer(
        keyword, state?.id, township?.id, pageNo,
      ),
      tAsString: (state) => state.name,
      sAsString: (township) => township.name,
      uAsString: (customer) => customer.name,
      compareFn: (a, b) => a.id == b.id,
      onMultiSelected: (values) => setState(() => selectedCustomers = values),
      multiValidator: (values) => values == null || values.isEmpty
          ? 'Required choose at least one customer' : null,
      itemBuilder: (context, customer, isDisabled, isSelected) => ListTile(
        title: Text(customer.name),
        subtitle: Text(customer.address),
        selected: isSelected,
      ),
      popupColor: const Color(0xFFFFE7E7),
      dropDownHeader: 'Select customers',
      allTText: 'All States',
      allSText: 'All Townships',
      allCText: 'All Customers',
      searchTText: 'Search State',
      searchSText: 'Search Township',
      searchCText: 'Search Customer',
    );
  }
}
