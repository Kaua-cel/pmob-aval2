import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/data/services/supabase_configuration.dart';
import 'package:pmob_aval2/state/operation_error_message.dart';

void main() {
  group('classifyOperationError', () {
    test('identifies configuration, timeout, invalidResponse, and communication errors', () {
      expect(
        classifyOperationError(const SupabaseConfigurationException('missing key')),
        OperationErrorKind.configuration,
      );
      expect(
        classifyOperationError(TimeoutException('request timed out')),
        OperationErrorKind.timeout,
      );
      expect(
        classifyOperationError(const FormatException('bad payload')),
        OperationErrorKind.invalidResponse,
      );
      expect(classifyOperationError(StateError('offline')), OperationErrorKind.communication);
    });
  });

  group('describeReadError and describeWriteError', () {
    test('returns clear Portuguese messages for each error category', () {
      expect(
        describeReadError(const SupabaseConfigurationException('SUPABASE_URL missing')),
        'Configuração de acesso à nuvem ausente ou inválida. Verifique a inicialização do aplicativo.',
      );
      expect(
        describeReadError(TimeoutException('slow network')),
        'A consulta demorou mais que o esperado. Verifique sua conexão e tente novamente.',
      );
      expect(
        describeReadError(const FormatException('missing id')),
        'Os dados recebidos do servidor são inválidos. Tente novamente.',
      );
      expect(
        describeReadError(StateError('socket closed')),
        'Não foi possível acessar os registros. Tente novamente.',
      );

      expect(
        describeWriteError(const SupabaseConfigurationException('SUPABASE_ANON_KEY missing')),
        'Configuração de acesso à nuvem ausente ou inválida. Não foi possível salvar o objeto.',
      );
      expect(
        describeWriteError(TimeoutException('write timeout')),
        'O envio demorou mais que o esperado. Verifique sua conexão e tente novamente.',
      );
      expect(
        describeWriteError(const FormatException('invalid row')),
        'Não foi possível confirmar o cadastro no servidor. Tente novamente.',
      );
      expect(
        describeWriteError(StateError('falha de conexão')),
        'Não foi possível cadastrar o objeto. Tente novamente.',
      );
    });

    test('never leaks secrets, URLs, or internal exception details in messages', () {
      final Exception sensitiveError = Exception(
        'service_role=secret_token_12345 https://private.internal.supabase.co stacktrace#0',
      );

      final String readMessage = describeReadError(sensitiveError);
      final String writeMessage = describeWriteError(sensitiveError);

      expect(readMessage, isNot(contains('secret_token_12345')));
      expect(readMessage, isNot(contains('service_role')));
      expect(readMessage, isNot(contains('supabase.co')));
      expect(writeMessage, isNot(contains('secret_token_12345')));
      expect(writeMessage, isNot(contains('service_role')));
      expect(writeMessage, isNot(contains('supabase.co')));
    });
  });
}
