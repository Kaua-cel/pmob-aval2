import 'dart:async';

import '../data/services/supabase_configuration.dart';

/// Categories of asynchronous operation failures handled by the presentation layer.
enum OperationErrorKind {
  /// Missing or invalid public cloud configuration.
  configuration,

  /// Operation exceeded the expected response time.
  timeout,

  /// Remote payload could not be parsed or validated.
  invalidResponse,

  /// Network, remote service, or unexpected communication failure.
  communication,
}

/// Classifies [error] into an [OperationErrorKind] without exposing internal details.
OperationErrorKind classifyOperationError(Object? error) {
  if (error is SupabaseConfigurationException) {
    return OperationErrorKind.configuration;
  }
  if (error is TimeoutException) {
    return OperationErrorKind.timeout;
  }
  if (error is FormatException) {
    return OperationErrorKind.invalidResponse;
  }
  return OperationErrorKind.communication;
}

/// Returns a safe, user-friendly Portuguese message for a failed list/read operation.
///
/// Never interpolates raw exception text, URLs, credentials, or stack traces.
String describeReadError(Object? error) {
  return switch (classifyOperationError(error)) {
    OperationErrorKind.configuration => 'Configuração de acesso à nuvem ausente ou inválida. Verifique a inicialização do aplicativo.',
    OperationErrorKind.timeout =>
      'A consulta demorou mais que o esperado. Verifique sua conexão e tente novamente.',
    OperationErrorKind.invalidResponse =>
      'Os dados recebidos do servidor são inválidos. Tente novamente.',
    OperationErrorKind.communication => 'Não foi possível acessar os registros. Tente novamente.',
  };
}

/// Returns a safe, user-friendly Portuguese message for a failed create/write operation.
///
/// Never interpolates raw exception text, URLs, credentials, or stack traces.
String describeWriteError(Object? error) {
  return switch (classifyOperationError(error)) {
    OperationErrorKind.configuration =>
      'Configuração de acesso à nuvem ausente ou inválida. Não foi possível salvar o objeto.',
    OperationErrorKind.timeout =>
      'O envio demorou mais que o esperado. Verifique sua conexão e tente novamente.',
    OperationErrorKind.invalidResponse =>
      'Não foi possível confirmar o cadastro no servidor. Tente novamente.',
    OperationErrorKind.communication => 'Não foi possível cadastrar o objeto. Tente novamente.',
  };
}
