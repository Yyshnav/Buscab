import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.38:5000/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Authentication
  static Future<Response> register(dynamic data) async {
    try {
      return await _dio.post('RegisterAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> registerOwner(dynamic data) async {
    try {
      return await _dio.post('OwnerRegisterAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> login(String username, String password) async {
    try {
      return await _dio.post(
        'LoginAPI',
        data: {'username': username, 'password': password},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Profiles
  static Future<Response> getUserProfile(int loginId) async {
    try {
      return await _dio.get('UserProfileAPI/$loginId/');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> updateUserProfile(int loginId, dynamic data) async {
    try {
      return await _dio.put('UserProfileAPI/$loginId/', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getOwnerProfile(int loginId) async {
    try {
      return await _dio.get('OwnerProfileAPI/$loginId');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> updateOwnerProfile(int loginId, dynamic data) async {
    try {
      return await _dio.post('OwnerProfileAPI/$loginId', data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Owner Bookings
  static Future<Response> getOwnerBookings(int ownerLoginId) async {
    try {
      return await _dio.get('OwnerBookingAPI/$ownerLoginId');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> updateBookingStatus(
    int bookingId,
    String status,
  ) async {
    try {
      return await _dio.post(
        'UpdateBookingStatusAPI',
        data: {'booking_id': bookingId, 'status': status},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Owner Complaints & Feedback
  static Future<Response> submitOwnerComplaint(dynamic data) async {
    try {
      return await _dio.post('OwnerComplaintAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getOwnerComplaints(int ownerLoginId) async {
    try {
      return await _dio.get('OwnerComplaintAPI/$ownerLoginId');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getOwnerFeedback(int ownerLoginId) async {
    try {
      return await _dio.get('OwnerFeedbackAPI/$ownerLoginId');
    } catch (e) {
      rethrow;
    }
  }

  // Bus Management
  static Future<Response> getAllBuses() async {
    try {
      return await _dio.get('ViewBusAPI');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> addBus(dynamic data) async {
    try {
      return await _dio.post('AddBusAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> deleteBus(int id) async {
    try {
      return await _dio.get('DeleteBusAPI/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Complaints & Feedback
  static Future<Response> submitComplaint(dynamic data) async {
    try {
      return await _dio.post('ComplaintAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getComplaints(int userId) async {
    try {
      return await _dio.get('ComplaintAPI/$userId');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> submitFeedback(dynamic data) async {
    try {
      return await _dio.post('FeedbackAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getAllFeedbacks() async {
    try {
      return await _dio.get('FeedbackAPI');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getNotifications() async {
    try {
      return await _dio.get('NotificationAPI');
    } catch (e) {
      rethrow;
    }
  }

  // Vehicle Management
  static Future<Response> addVehicle(dynamic data) async {
    try {
      return await _dio.post('VehicleAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getVehicles({
    int? loginId,
    String? pickup,
    String? drop,
    String? cabType,
  }) async {
    try {
      String url = loginId != null ? 'VehicleAPI/$loginId' : 'VehicleAPI';
      Map<String, dynamic> queryParams = {};
      if (pickup != null) queryParams['pickup'] = pickup;
      if (drop != null) queryParams['drop'] = drop;
      if (cabType != null) queryParams['cab_type'] = cabType;

      return await _dio.get(url, queryParameters: queryParams);
    } catch (e) {
      rethrow;
    }
  }

  // Booking, Lift, Rating
  static Future<Response> bookVehicle(dynamic data) async {
    try {
      return await _dio.post('BookingAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getUserBookings(int userId) async {
    try {
      return await _dio.get('BookingAPI/$userId');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getLifts({int? userId, int? excludeUserId}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (userId != null) queryParams['user_id'] = userId;
      if (excludeUserId != null) queryParams['exclude_user_id'] = excludeUserId;

      return await _dio.get('LiftAPI', queryParameters: queryParams);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> offerLift(dynamic data) async {
    try {
      return await _dio.post('LiftAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> submitRating(dynamic data) async {
    try {
      return await _dio.post('RatingAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Lift Request API
  static Future<Response> requestLift(dynamic data) async {
    try {
      return await _dio.post('LiftRequestAPI', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getIncomingLiftRequests(int liftId) async {
    try {
      return await _dio.get('LiftRequestAPI/status/$liftId');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> getMyLiftRequests(int loginId) async {
    try {
      return await _dio.get('LiftRequestAPI/$loginId');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> updateLiftRequestStatus(
    int requestId,
    String status,
  ) async {
    try {
      return await _dio.post(
        'UpdateLiftRequestStatusAPI',
        data: {'request_id': requestId, 'status': status},
      );
    } catch (e) {
      rethrow;
    }
  }
}
