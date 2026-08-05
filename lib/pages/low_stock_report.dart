import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/pages/drawer.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:due_kasir/widget/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:go_router/go_router.dart';

class LowStockReportScreen extends HookWidget {
  const LowStockReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final search = useTextEditingController();
    useListenable(search);

    final lowStockItems = useMemoized(() => futureSignal(() async {
          return Database().getLowStock();
        }));
    final state = lowStockItems.watch(context);

    // Filter items in memory based on search query
    final filteredItems = useMemoized(() {
      if (!state.hasValue || state.value == null) return <ItemModel>[];
      final query = search.text.toLowerCase();
      if (query.isEmpty) return state.value!;
      return state.value!.where((item) {
        return item.nama.toLowerCase().contains(query) ||
            item.code.toLowerCase().contains(query);
      }).toList();
    }, [state.value, search.text]);

    return Scaffold(
      drawer: const NavDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Low Stock Report'),
        actions: [
          ShadButton.ghost(
            onPressed: () => lowStockItems.refresh(),
            icon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.refresh, size: 16),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Banner Card
              ShadCard(
                title: Text(
                  '${state.value?.length ?? 0} Low Stock Alerts',
                  style: theme.textTheme.h3.copyWith(color: Colors.red),
                ),
                description: const Text(
                  'These items require restocking. Their inventory quantity has dropped below their specified low stock threshold.',
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextFormField(
                controller: search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by item name or code...',
                ),
              ),
              const SizedBox(height: 20),

              // Table Headers / Desktop list
              Expanded(
                child: state.map(
                  data: (items) {
                    if (filteredItems.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            'No low stock items found.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Item Name')),
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Current Stock')),
                            DataColumn(label: Text('Limit')),
                            DataColumn(label: Text('Purchase Price')),
                            DataColumn(label: Text('Sale Price')),
                          ],
                          rows: filteredItems.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(Text(item.nama)),
                                DataCell(Text(item.code)),
                                DataCell(
                                  Text(
                                    '${item.jumlahBarang}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(Text('${item.lowStockLimit ?? 5}')),
                                DataCell(Text(currency.format(item.hargaDasar))),
                                DataCell(Text(currency.format(item.hargaJual))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  error: (err, _) => Center(
                    child: Text('Error: $err'),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
