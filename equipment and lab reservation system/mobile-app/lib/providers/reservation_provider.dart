import 'package:flutter/foundation.dart';

import '../models/reservation_model.dart';
import '../services/reservation_service.dart';

class ReservationProvider extends ChangeNotifier {
  ReservationProvider({ReservationService? service})
      : _service = service ?? ReservationService();

  final ReservationService _service;
  List<ReservationModel> reservations = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      reservations = await _service.list();
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancel(int id) async {
    await _service.cancel(id);
    await load();
  }
}