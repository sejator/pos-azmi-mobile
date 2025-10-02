import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pos_azmi/core/navigation_service.dart';
import 'package:pos_azmi/helpers/notifikasi_helper.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pos_azmi/providers/order_notifier.dart';
import 'dart:convert';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final _pusher = PusherChannelsFlutter.getInstance();
  final _player = AudioPlayer();
  bool _connected = false;

  Future<void> init({required int outletId}) async {
    if (_connected || outletId == 0) return;

    try {
      await _pusher.init(
        apiKey: dotenv.env['PUSHER_APP_KEY'] ?? '',
        cluster: dotenv.env['PUSHER_APP_CLUSTER'] ?? '',
        onEvent: (event) async {
          if (event.eventName == 'order.paid') {
            try {
              final Map<String, dynamic> payload = jsonDecode(event.data);
              final order = payload['order'];

              if (order?['source'] != 'customer') return;

              await _player.play(AssetSource('audio/terima-order.wav'));

              final ctx = navigatorKey.currentContext;
              if (ctx == null || !ctx.mounted) return;

              Provider.of<OrderNotifier>(ctx, listen: false).notifyNewOrder();

              showSnackbar(
                ctx,
                'Orderan baru masuk',
                icon: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              );
            } catch (e) {
              // Handle JSON decoding errors or other exceptions
            }
          }
        },
        onSubscriptionSucceeded: (channelName, data) {
          // Debugging output for successful subscription
        },
      );

      await _pusher.subscribe(channelName: 'orders.$outletId');
      await _pusher.connect();
      _connected = true;
    } catch (e) {
      // Handle connection errors
      _connected = false;
    }
  }

  Future<void> dispose() async {
    await _pusher.disconnect();
    _connected = false;
  }
}
