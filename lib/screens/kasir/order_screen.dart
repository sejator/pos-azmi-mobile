import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_azmi/core/api_client.dart';
import 'package:pos_azmi/core/storage.dart';
import 'package:pos_azmi/helpers/format_helper.dart';
import 'package:pos_azmi/helpers/notifikasi_helper.dart';
import 'package:flutter/services.dart';
import 'package:pos_azmi/models/order_model.dart';
import 'package:pos_azmi/providers/order_notifier.dart';
import 'package:pos_azmi/screens/kasir/success_screen.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int currentPage = 1;
  int totalPages = 1;
  String search = '';
  String status = 'paid';
  String? startDate;
  String? endDate;

  bool isLoading = true;
  bool isFetchingMore = false;

  List<OrderModel> orders = [];
  final searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late OrderNotifier orderNotifier;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    scrollController.addListener(_onScroll);

    Future.microtask(() {
      orderNotifier = Provider.of<OrderNotifier>(context, listen: false);
      orderNotifier.addListener(_onNewOrderReceived);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    orderNotifier.removeListener(_onNewOrderReceived);

    super.dispose();
  }

  void _onNewOrderReceived() {
    _fetchOrders();
  }

  void _onScroll() {
    if (!isFetchingMore &&
        !isLoading &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        currentPage < totalPages) {
      _fetchMoreOrders();
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);

    try {
      final outlet = await Storage.getOutlet();
      final outletId = outlet?.id;
      final res = await ApiClient.dio.get('/orders', queryParameters: {
        'page': 1,
        'perPage': 10,
        'outlet_id': outletId,
        'is_finished': false,
        'is_process': false,
        if (search.isNotEmpty) 'search': search,
        if (status.isNotEmpty) 'status': status,
        if (startDate != null && endDate != null) ...{
          'startDate': startDate,
          'endDate': endDate,
        },
      });

      final List data = res.data['data'];
      final pagination = res.data['pagination'];

      setState(() {
        orders = data.map((e) => OrderModel.fromJson(e)).toList();
        currentPage = pagination['current_page'];
        totalPages = pagination['last_page'];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      showSnackbar(
        context,
        'Gagal memuat order',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _fetchMoreOrders() async {
    if (currentPage >= totalPages) return;

    setState(() => isFetchingMore = true);

    try {
      final outlet = await Storage.getOutlet();
      final outletId = outlet?.id;
      final nextPage = currentPage + 1;
      final res = await ApiClient.dio.get('/orders', queryParameters: {
        'page': nextPage,
        'perPage': 10,
        'outlet_id': outletId,
        'is_finished': false,
        'is_process': false,
        if (search.isNotEmpty) 'search': search,
        if (status.isNotEmpty) 'status': status,
        if (startDate != null && endDate != null) ...{
          'startDate': startDate,
          'endDate': endDate,
        },
      });

      final List data = res.data['data'];
      final pagination = res.data['pagination'];

      setState(() {
        orders.addAll(data.map((e) => OrderModel.fromJson(e)).toList());
        currentPage = pagination['current_page'];
        totalPages = pagination['last_page'];
        isFetchingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isFetchingMore = false);

      showSnackbar(
        context,
        'Gagal memuat order',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = DateFormat('yyyy-MM-dd').format(picked.start);
        endDate = DateFormat('yyyy-MM-dd').format(picked.end);
        currentPage = 1;
      });
      _fetchOrders();
    }
  }

  Widget _buildOrderCard(OrderModel order) {
    final isPaid = order.status == 'paid';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                order.noAntrian,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('No Order',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          order.invoice,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: order.invoice));
                          showSnackbar(
                            context,
                            'Invoice disalin',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...order.items.map((item) {
              final itemPrice = FormatHelper.toRupiah(item.price);
              final itemTotal = FormatHelper.toRupiah(item.total);
              final variant =
                  item.variants.isEmpty ? '-' : '- ${item.variants.first.name}';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(
                              '${item.quantity} x ${item.name} $variant ($itemPrice)')),
                      Text(itemTotal),
                    ],
                  ),
                  if (item.note != null && item.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 8),
                      child: Text("- Catatan: ${item.note}",
                          style: const TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(height: 6),
                ],
              );
            }),
            Text(
              'Total: ${FormatHelper.toRupiah(order.total)} - ${order.paymentMethod}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : Icons.hourglass_top,
                      color: isPaid ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.paymentStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                        Text(order.orderDate,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
                if (isPaid)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Cetak Struk'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuccessScreen(autoPrint: false),
                          settings: RouteSettings(arguments: order.invoice),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: searchController,
                onSubmitted: (val) {
                  setState(() {
                    search = val;
                    currentPage = 1;
                  });
                  _fetchOrders();
                },
                decoration: InputDecoration(
                  hintText: 'Cari invoice...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              search = '';
                              currentPage = 1;
                            });
                            _fetchOrders();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter tanggal',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: _fetchOrders,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeaderBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const Center(child: Text('Tidak ada data order'))
                    : RefreshIndicator(
                        onRefresh: _fetchOrders,
                        child: ListView.builder(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: orders.length + (isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < orders.length) {
                              return _buildOrderCard(orders[index]);
                            } else {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
