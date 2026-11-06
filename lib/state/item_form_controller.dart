import 'package:flutter/foundation.dart';

import '../data/services/item_record_repository.dart';
import '../models/item_record.dart';
import 'operation_error_message.dart';

/// Estados possíveis da operação de cadastro de um item.
enum ItemFormState {
  /// Aguardando ação do usuário.
  idle,

  /// Gravação em andamento; novos envios são bloqueados.
  submitting,

  /// Gravação confirmada com sucesso.
  success,

  /// Gravação encerrada com erro; dados do formulário devem ser preservados.
  failure,
}

/// Controla a operação assíncrona de cadastro de um [ItemRecord].
///
/// Expõe [state] para que a interface indique progresso, sucesso e falha.
/// Após [ItemFormState.success], consulte [needsListRefresh] e chame
/// [acknowledgeSuccess] para retornar ao estado [ItemFormState.idle].
class ItemFormController extends ChangeNotifier {
  /// Cria um controller que usa [repository] para persistir registros.
  ItemFormController(this._repository);

  final ItemRecordRepository _repository;
  ItemFormState _state = ItemFormState.idle;
  Object? _error;
  ItemRecord? _lastFailedDraft;
  bool _needsListRefresh = false;

  /// Estado atual da operação de cadastro.
  ItemFormState get state => _state;

  /// Último erro capturado. Não nulo quando [state] é [ItemFormState.failure].
  Object? get error => _error;

  /// Mensagem segura em português descrevendo a falha atual, ou `null` fora do estado de erro.
  String? get errorMessage => _state == ItemFormState.failure ? describeWriteError(_error) : null;

  /// Último rascunho cuja gravação falhou, disponível para nova tentativa.
  ItemRecord? get lastFailedDraft => _lastFailedDraft;

  /// Indica se há uma operação malsucedida pendente que pode ser reenviada.
  bool get canRetry => _state == ItemFormState.failure && _lastFailedDraft != null;

  /// Verdadeiro quando um cadastro foi confirmado e a listagem deve ser recarregada.
  ///
  /// Redefinido para `false` após [acknowledgeSuccess].
  bool get needsListRefresh => _needsListRefresh;

  /// Envia [draft] para persistência remota.
  ///
  /// Não inicia uma nova operação se [state] já for [ItemFormState.submitting].
  /// Em caso de sucesso, transita para [ItemFormState.success] e define
  /// [needsListRefresh] como `true`.
  /// Em caso de falha, transita para [ItemFormState.failure] e preserva [error].
  Future<void> submit(ItemRecord draft) async {
    if (_state == ItemFormState.submitting) return;

    _state = ItemFormState.submitting;
    _error = null;
    _lastFailedDraft = null;
    _needsListRefresh = false;
    notifyListeners();

    try {
      await _repository.createItemRecord(draft);
      _state = ItemFormState.success;
      _needsListRefresh = true;
    } catch (error) {
      _error = error;
      _lastFailedDraft = draft;
      _state = ItemFormState.failure;
    }

    notifyListeners();
  }

  /// Tenta reenviar o último rascunho que falhou.
  ///
  /// Só executa quando [state] é [ItemFormState.failure], evitando envios
  /// duplicados após sucesso ou durante gravação em andamento.
  Future<void> retry() async {
    final ItemRecord? draft = _lastFailedDraft;
    if (_state != ItemFormState.failure || draft == null) {
      return;
    }
    await submit(draft);
  }

  /// Reconhece o sucesso e retorna ao estado [ItemFormState.idle].
  ///
  /// Deve ser chamado pela interface após processar [needsListRefresh].
  void acknowledgeSuccess() {
    if (_state != ItemFormState.success) return;
    _state = ItemFormState.idle;
    _lastFailedDraft = null;
    _needsListRefresh = false;
    notifyListeners();
  }

  /// Reseta para [ItemFormState.idle] descartando qualquer erro pendente.
  ///
  /// Não tem efeito quando [state] é [ItemFormState.submitting].
  void reset() {
    if (_state == ItemFormState.submitting) return;
    _state = ItemFormState.idle;
    _error = null;
    _lastFailedDraft = null;
    _needsListRefresh = false;
    notifyListeners();
  }
}
