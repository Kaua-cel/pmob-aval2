# Achados e Perdidos do Campus

Base Flutter do aplicativo de achados e perdidos do campus. Inclui tema Material 3 e
telas iniciais de listagem e cadastro.

## Pré-requisitos

- Flutter SDK 3.47 ou compatível
- Um dispositivo, emulador ou navegador suportado pelo Flutter

## Executar

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=<project-url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Substitua os valores pelos dados públicos do projeto Supabase. Não versione `service_role`,
senha do banco, token pessoal, chave administrativa ou um arquivo `.env` com valores reais.
Veja [docs/cloud-storage.md](docs/cloud-storage.md) para criar a tabela, aplicar a migration,
configurar RLS e validar a persistência entre instalações.

Para executar no navegador, adicione `-d chrome` ao comando acima quando o Chrome estiver
disponível.

## Validar

```bash
dart format .
flutter analyze
flutter test
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
