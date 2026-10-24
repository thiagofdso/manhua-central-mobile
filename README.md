# Manhua Central — Mobile App (Flutter)

Aplicativo móvel multiplataforma (Android & iOS) em Flutter para consumo e leitura offline-first de manhuas, manhwas e mangás, desenhado para publicação na Google Play Store.

## Requisitos
- Flutter SDK (canal `stable`, 3.x+)
- Dart SDK (3.x+)
- Android Studio / Xcode

## Comandos Úteis
```bash
# Instalar dependências
flutter pub get

# Executar análise estática de código
flutter analyze

# Executar testes unitários com cobertura
flutter test --coverage

# Executar no dispositivo ou emulador conectado
flutter run

# Gerar Android App Bundle para release na Google Play
flutter build appbundle --release
```

## Pipeline de Validação Pré-PR
Todo Pull Request para `desenv` ou `main` executa automaticamente a pipeline `.github/workflows/pr-check.yml` validando `flutter analyze` e `flutter test`.
