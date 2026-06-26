enum DroneConnectionState {
  disconnected,
  connecting,
  connected,
  error;

  String get label {
    switch (this) {
      case DroneConnectionState.disconnected:
        return 'Desconectado';
      case DroneConnectionState.connecting:
        return 'Conectando...';
      case DroneConnectionState.connected:
        return 'Conectado';
      case DroneConnectionState.error:
        return 'Erro de conexão';
    }
  }
}
