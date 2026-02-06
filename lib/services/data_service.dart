import 'firebase_service.dart';

class DataService {
  // Client operations
  static Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final querySnapshot = await FirebaseService.getClients();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
// print('Error getting clients: $e');
      return [];
    }
  }

  static Future<bool> addClient(Map<String, dynamic> clientData) async {
    try {
      await FirebaseService.createClient(clientData);
      return true;
    } catch (e) {
// print('Error adding client: $e');
      return false;
    }
  }

  static Future<bool> updateClient(String clientId, Map<String, dynamic> data) async {
    try {
      await FirebaseService.updateClient(clientId, data);
      return true;
    } catch (e) {
// print('Error updating client: $e');
      return false;
    }
  }

  static Future<bool> deleteClient(String clientId) async {
    try {
      await FirebaseService.deleteClient(clientId);
      return true;
    } catch (e) {
// print('Error deleting client: $e');
      return false;
    }
  }

  // Order operations
  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final querySnapshot = await FirebaseService.getOrders();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
// print('Error getting orders: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getOrdersByClient(String clientId) async {
    try {
      final querySnapshot = await FirebaseService.getOrdersByClient(clientId);
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
// print('Error getting client orders: $e');
      return [];
    }
  }

  static Future<bool> addOrder(Map<String, dynamic> orderData) async {
    try {
      await FirebaseService.createOrder(orderData);
      return true;
    } catch (e) {
// print('Error adding order: $e');
      return false;
    }
  }

  static Future<bool> updateOrder(String orderId, Map<String, dynamic> data) async {
    try {
      await FirebaseService.updateOrder(orderId, data);
      return true;
    } catch (e) {
// print('Error updating order: $e');
      return false;
    }
  }

  // User operations
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final docSnapshot = await FirebaseService.getUserProfile(uid);
      if (docSnapshot != null && docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } catch (e) {
// print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await FirebaseService.updateUserProfile(uid, data);
      return true;
    } catch (e) {
// print('Error updating user profile: $e');
      return false;
    }
  }

  // Analytics
  static Future<void> logUserAction(String action, {Map<String, dynamic>? parameters}) async {
    try {
      await FirebaseService.logEvent(
        name: action,
        parameters: parameters,
      );
    } catch (e) {
// print('Error logging event: $e');
    }
  }

  // Real-time listeners
  static Stream<List<Map<String, dynamic>>> getClientsStream() {
    return FirebaseService.clientsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Stream<List<Map<String, dynamic>>> getOrdersStream() {
    return FirebaseService.ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Stream<List<Map<String, dynamic>>> getOrdersByClientStream(String clientId) {
    return FirebaseService.ordersCollection
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
