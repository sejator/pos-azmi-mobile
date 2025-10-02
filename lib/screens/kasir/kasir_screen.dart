import 'package:flutter/material.dart';
import 'package:pos_azmi/screens/kasir/antrian_screen.dart';
import 'package:provider/provider.dart';
import 'package:pos_azmi/models/outlet_model.dart';
import 'package:pos_azmi/providers/cart_provider.dart';
import 'package:pos_azmi/screens/kasir/order_screen.dart';
import 'package:pos_azmi/screens/kasir/riwayat_transaksi_screen.dart';
import 'package:pos_azmi/screens/kasir/transaksi_screen.dart';
import 'package:pos_azmi/screens/kasir/cart_items_screen.dart';

class KasirScreen extends StatelessWidget {
  final Outlet outlet;
  final int initialTabIndex;

  const KasirScreen({
    super.key,
    required this.outlet,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: DefaultTabController(
        initialIndex: initialTabIndex,
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Kasir - ${outlet.name}"),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartItemsScreen(),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Consumer<CartProvider>(
                        builder: (context, cart, _) => cart.totalQuantity == 0
                            ? const SizedBox.shrink()
                            : CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Text(
                                  '${cart.totalQuantity}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              )
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Transaksi'),
                Tab(text: 'Order'),
                Tab(text: 'Antrian'),
                Tab(text: 'Riwayat'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              TransaksiScreen(),
              OrderScreen(),
              AntrianScreen(),
              RiwayatTransaksiScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
