import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Single authenticated socket.io connection, shared across match-live and
/// notification features. socket_io_client picks the right transport per
/// platform automatically (WebSocket everywhere, including Web/Windows/macOS).
class SocketService {
  SocketService({required this._tokenStorage});

  final TokenStorage _tokenStorage;
  io.Socket? _socket;
  Future<io.Socket>? _connecting;
  final Set<int> _joinedMatchIds = <int>{};
  final Set<int> _joinedTrainingIds = <int>{};

  Future<io.Socket> connect() async {
    if (_socket != null && _socket!.connected) return _socket!;
    // BUG CORRIGÉ: deux appels concurrents à connect() (ex: un écran de
    // match live et un écran de notifications montés en même temps)
    // pouvaient chacun créer un NOUVEAU socket avant que le premier n'ait
    // fini de se connecter (`_socket!.connected` encore false), laissant
    // le socket précédent orphelin (jamais disconnect()/dispose()) et
    // ouvrant deux connexions au serveur pour le même utilisateur.
    return _connecting ??= _doConnect().whenComplete(() => _connecting = null);
  }

  Future<io.Socket> _doConnect() async {
    final token = await _tokenStorage.accessToken;
    // BUG CORRIGÉ: le token n'était capturé qu'une fois, ici. socket.io
    // reconnecte automatiquement après une coupure réseau (option
    // `reconnection`, activée par défaut — `disableAutoConnect()` ne
    // désactive que la CONNEXION initiale, pas les reconnexions
    // ultérieures) : la reconnexion réutilisait ce même token capturé, qui
    // avait pu expirer entre-temps (durée de vie courte, ex. 15 min côté
    // backend). Résultat : après une simple coupure Wi-Fi sur une session
    // un peu longue, le socket échouait silencieusement à se reconnecter
    // (auth refusée) et l'app perdait les mises à jour live/notifications
    // sans que rien ne le signale à l'utilisateur. On désactive la
    // reconnexion automatique du client et on la pilote nous-mêmes avec un
    // token frais à chaque tentative.
    final existing = _socket;
    if (existing != null) {
      // Reuse the same Socket instance so feature listeners survive a network
      // interruption. Updating auth before connect sends the freshest JWT in
      // the next Socket.IO handshake.
      existing.auth = {'token': token};
      existing.connect();
      return existing;
    }

    final socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .disableReconnection()
          .setAuth({'token': token})
          .build(),
    );
    _socket = socket;

    socket.onConnectError((data) => _scheduleReconnect());
    socket.onDisconnect((_) => _scheduleReconnect());
    socket.onConnect((_) {
      // Socket.IO rooms are connection-scoped. Rejoin every match that is
      // still being watched after a successful reconnect.
      for (final matchId in _joinedMatchIds) {
        socket.emit('match:join', matchId);
      }
      for (final trainingId in _joinedTrainingIds) {
        socket.emit('attendance:join', trainingId);
      }
    });

    socket.connect();
    return socket;
  }

  bool _reconnectScheduled = false;

  void _scheduleReconnect() {
    if (_reconnectScheduled) return;
    _reconnectScheduled = true;
    Future.delayed(const Duration(seconds: 3), () async {
      _reconnectScheduled = false;
      if (_socket == null) {
        return; // disconnect() was called meanwhile — don't resurrect it
      }
      await connect();
    });
  }

  io.Socket? get socket => _socket;

  void joinMatch(int matchId) {
    _joinedMatchIds.add(matchId);
    if (_socket?.connected == true) {
      _socket!.emit('match:join', matchId);
    }
  }

  void leaveMatch(int matchId) {
    _joinedMatchIds.remove(matchId);
    if (_socket?.connected == true) {
      _socket!.emit('match:leave', matchId);
    }
  }

  void joinTrainingAttendance(int trainingId) {
    _joinedTrainingIds.add(trainingId);
    if (_socket?.connected == true) {
      _socket!.emit('attendance:join', trainingId);
    }
  }

  void leaveTrainingAttendance(int trainingId) {
    _joinedTrainingIds.remove(trainingId);
    if (_socket?.connected == true) {
      _socket!.emit('attendance:leave', trainingId);
    }
  }

  void disconnect() {
    _reconnectScheduled =
        false; // an in-flight _scheduleReconnect must not resurrect the socket after an explicit disconnect
    _joinedMatchIds.clear();
    _joinedTrainingIds.clear();
    final socket = _socket;
    _socket = null;
    socket?.dispose();
  }
}
