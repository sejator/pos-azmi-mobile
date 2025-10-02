import 'package:flutter/material.dart';
import 'package:pos_azmi/core/storage.dart';
import 'package:pos_azmi/helpers/notifikasi_helper.dart';
import 'package:provider/provider.dart';
import 'package:pos_azmi/screens/kasir/cart_items_screen.dart';
import 'package:pos_azmi/core/api_client.dart';
import 'package:pos_azmi/models/product_model.dart';
import 'package:pos_azmi/models/cart_item.dart';
import 'package:pos_azmi/providers/cart_provider.dart';
import 'package:pos_azmi/helpers/format_helper.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  List<ProductModel> products = [];
  bool loading = true;
  String _searchTerm = '';

  final Map<int, TextEditingController> _qtyControllers = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final outlet = await Storage.getOutlet();
      final outletId = outlet?.id;
      final res = await ApiClient.dio.get('/products', queryParameters: {
        'outlet_id': outletId,
      });

      final List<dynamic> data = res.data['data']['products'];
      final List<ProductModel> loaded =
          data.map((item) => ProductModel.fromJson(item)).toList();

      if (!mounted) return;
      setState(() {
        products = loaded;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      showSnackbar(
        context,
        'Gagal memuat data',
        backgroundColor: Colors.red,
      );
    }
  }

  void _addToCart(ProductModel item, int quantity,
      [ProductVariantModel? variant]) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    final cartItem = CartItem(
      productId: item.id,
      productName: '${item.name} - ${item.unit}',
      productPrice: variant?.price ?? item.price,
      variantId: variant?.id,
      variantName: variant?.name,
      quantity: quantity,
      note: null,
    );

    cart.addToCart(cartItem);
    await cart.checkAndApplyPromotions();
  }

  List<Map<String, dynamic>> getFlattenedProductVariants(
      List<ProductModel> products) {
    final List<Map<String, dynamic>> result = [];

    for (final product in products) {
      if (product.variants.isEmpty) {
        result.add({
          'product': product,
          'variant': null,
        });
      } else {
        for (final variant in product.variants) {
          result.add({
            'product': product,
            'variant': variant,
          });
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final filteredProducts = getFlattenedProductVariants(
      products
          .where((p) => p.name.toLowerCase().contains(_searchTerm))
          .toList(),
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchTerm = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Muat ulang produk',
                  onPressed: () {
                    _searchFocusNode.unfocus();
                    setState(() {
                      loading = true;
                      _searchController.clear();
                      _searchTerm = '';
                    });
                    _loadProducts();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : filteredProducts.isEmpty
              ? const Center(child: Text('Tidak ada produk ditemukan'))
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: Stack(
                    children: [
                      ListView.builder(
                        padding: const EdgeInsets.only(
                            bottom: 120, left: 10, right: 10),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final map = filteredProducts[index];
                          final ProductModel item = map['product'];
                          final variant =
                              map['variant'] as ProductVariantModel?;

                          final controllerKey = variant?.id ?? item.id;

                          _qtyControllers.putIfAbsent(
                            controllerKey,
                            () => TextEditingController(text: '1'),
                          );
                          final qtyController = _qtyControllers[controllerKey]!;

                          final displayName = variant != null
                              ? '${item.name} (${variant.name}) - ${item.unit}'
                              : '${item.name} - ${item.unit}';

                          final displayPrice = variant?.price ?? item.price;
                          final stock = variant?.stock ?? item.stock ?? 0;

                          return Opacity(
                            opacity: stock <= 0 ? 0.5 : 1.0,
                            child: Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Gambar produk
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.image,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.image_not_supported,
                                          size: 70,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Detail produk + aksi
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Stok: $stock',
                                            style: TextStyle(
                                              color: stock <= 0
                                                  ? Colors.red
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                FormatHelper.toRupiah(
                                                    displayPrice),
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 50,
                                                    height: 35,
                                                    child: TextFormField(
                                                      controller: qtyController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      textAlign:
                                                          TextAlign.center,
                                                      enabled: stock > 0,
                                                      decoration:
                                                          const InputDecoration(
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        6),
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  if (!isKeyboardOpen)
                                                    SizedBox(
                                                        height: 35,
                                                        child: stock <= 0
                                                            ? Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        12),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade400,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              6),
                                                                ),
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child:
                                                                    const Text(
                                                                  'Habis',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              )
                                                            : ElevatedButton
                                                                .icon(
                                                                onPressed: () {
                                                                  final input =
                                                                      int.tryParse(
                                                                          qtyController
                                                                              .text);
                                                                  final qty = (input !=
                                                                              null &&
                                                                          input >
                                                                              0)
                                                                      ? input
                                                                      : 1;
                                                                  _addToCart(
                                                                      item,
                                                                      qty,
                                                                      variant);
                                                                  qtyController
                                                                          .text =
                                                                      '1';
                                                                  _searchFocusNode
                                                                      .unfocus();
                                                                  setState(() {
                                                                    _searchTerm =
                                                                        '';
                                                                    _searchController
                                                                        .clear();
                                                                  });
                                                                },
                                                                icon:
                                                                    const Icon(
                                                                  Icons
                                                                      .add_shopping_cart,
                                                                  size: 18,
                                                                ),
                                                                label:
                                                                    const Text(
                                                                  'Tambah',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  minimumSize:
                                                                      const Size(
                                                                          100,
                                                                          40),
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8),
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  tapTargetSize:
                                                                      MaterialTapTargetSize
                                                                          .shrinkWrap,
                                                                ),
                                                              )),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            if (cart.items.isEmpty) return const SizedBox();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                    top: BorderSide(
                                        color: Colors.grey, width: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.shopping_cart, size: 28),
                                      if (cart.totalQuantity > 0)
                                        Positioned(
                                          top: -6,
                                          right: -6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                                minWidth: 20, minHeight: 20),
                                            child: Text(
                                              '${cart.totalQuantity}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Total: ',
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14),
                                            ),
                                            TextSpan(
                                              text: FormatHelper.toRupiah(
                                                  cart.total),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CartItemsScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Detail Pesanan',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary, // purple
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CartItemsScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(100, 40),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                    ),
                                    child: const Text(
                                      'Lanjut',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}
