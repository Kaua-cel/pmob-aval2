# Achados e Perdidos do Campus

Aplicativo móvel desenvolvido em **Flutter e Dart** para divulgação e consulta de objetos perdidos e encontrados no campus universitário, com persistência remota em nuvem gratuita (**Supabase Postgres**).

- **Instituição:** Universidade Estadual do Piauí (UESPI)
- **Curso:** Tecnologia em Sistemas de Computação
- **Disciplina:** Programação para Dispositivos Móveis
- **Professor:** Eyder Rios
- **Avaliação:** 2ª Avaliação — Trabalho de Implementação

---

## Equipe (Integrantes)

Todos os integrantes participaram do desenvolvimento, possuem commits identificáveis no repositório e revisaram a solução integrada:

| Nome Completo | Conta GitHub |
| :--- | :--- |
| **Alan Rodrigues de Castro** | `@alanrcastro` (`Alan Castro`) |
| **Eric Silva Patricio** | `@ericsilva` (`Eric Silva`) |
| **José Maranhão da Silva Neto** | `@maranhaojose` (`Jose Neto`) |
| **Kauã Neres Moura** | `@Kaua-cel` (`Neres-Dev`) |

---

## Funcionalidades Implementadas

### 1. Listagem de Objetos (`RF01`)
- Carregamento assíncrono dos registros persistidos na nuvem ao abrir o aplicativo.
- Exibição completa de **nome**, **local**, **situação** (`Perdido` ou `Encontrado`) e **descrição** de cada objeto em cartões Material 3 (`CartaoRegistroItem`).
- Identificação visual e textual clara da situação por meio de cores semânticas, ícones e rótulos em português (`Perdido` / `Encontrado`).
- Ordenação decrescente por data e hora de cadastro (**registros mais recentes primeiro**).
- Atualização manual da listagem tanto pelo botão **Atualizar listagem** na `AppBar` quanto pelo gesto de puxar para atualizar (`RefreshIndicator`).

### 2. Cadastro de Objetos (`RF02`)
- Formulário dedicado com validação obrigatória antes do envio:
  - **Nome do objeto:** obrigatório, máximo de 60 caracteres.
  - **Descrição:** obrigatória, máximo de 200 caracteres.
  - **Local:** obrigatório.
  - **Situação:** seleção entre `Perdido` e `Encontrado` (`SegmentedButton`).
- Registro automático de identificador (`id` UUID) e data/hora (`created_at` em UTC) diretamente pelo servidor de banco de dados.
- Retorno automático para a tela de listagem após confirmação de gravação, exibindo imediatamente o novo objeto cadastrado.

### 3. Assincronismo, Tratamento de Falhas e Novas Tentativas (`RF03`)
- Operações de leitura e escrita 100% assíncronas sem bloquear ou congelar a interface.
- Indicadores visuais de progresso (`CircularProgressIndicator`) durante o carregamento da listagem e durante o envio do formulário (`Salvando...`).
- Prevenção de envios duplicados e requisições concorrentes (desabilitação de campos, botões e navegação de retorno durante a gravação).
- Mapeamento de erros de rede, tempo limite (`timeout`), resposta inválida e configuração para mensagens claras em português, sem expor detalhes internos ou segredos.
- Ação explícita de **Tentar novamente** tanto na tela de listagem (`EstadoFalhaLista`) quanto no formulário de cadastro (preservando os dados digitados sem duplicar registros).

### 4. Gerenciamento de Estado e Interface Responsiva (`RF04`, `RNF01`, `RNF02`)
- Gerenciamento de estado com `ChangeNotifier` através de `ItemListController` e `ItemFormController`, mantendo separação clara entre interface (`lib/ui`), estado (`lib/state`), modelos (`lib/models`) e acesso a dados (`lib/data/services`).
- Componentes **Material 3** com interface e tooltips integralmente em **português**.
- Layout responsivo adaptado a telas compactas, orientação paisagem, teclados virtuais abertos e telas largas, evitando overflow e mantendo todos os controles acessíveis.

---

## Serviço de Armazenamento em Nuvem (`RF05`)

- **Serviço utilizado:** **Supabase (PostgreSQL — Plano Gratuito / Free Tier)**.
- **Tabela remota:** `public.item_records` (esquema e políticas versionados em [`supabase/migrations/20261029120000_create_item_records.sql`](supabase/migrations/20261029120000_create_item_records.sql)).
- **Controle de acesso (Row Level Security — RLS):**
  - O aplicativo utiliza apenas parâmetros públicos de cliente (`SUPABASE_URL` e `SUPABASE_ANON_KEY`), protegidos por RLS no banco de dados.
  - O papel público `anon` possui permissão exclusivamente para `SELECT` e `INSERT` nas colunas `name`, `description`, `location` e `status`.
  - Operações de `UPDATE` e `DELETE` são bloqueadas, e os campos `id` e `created_at` são gerados pelo banco (`gen_random_uuid()` e `now()`).
- **Aviso de uso:** Por se tratar de um aplicativo acadêmico sem autenticação, devem ser cadastrados exclusivamente **dados demonstrativos**, sem informações pessoais ou sensíveis.

Consulte [`docs/cloud-storage.md`](docs/cloud-storage.md) para detalhes adicionais sobre a arquitetura da tabela, políticas RLS e roteiro de verificação entre múltiplas instalações.

---

## Estrutura do Projeto

```text
lib/
├── app.dart                                         # Configuração do MaterialApp, tema e rotas
├── main.dart                                        # Inicialização do Supabase e injeção dos controladores
├── data/
│   └── services/
│       ├── item_record_repository.dart              # Contrato abstrato de persistência remota
│       ├── supabase_configuration.dart              # Leitura e validação dos parâmetros --dart-define
│       └── supabase_item_record_repository.dart     # Implementação REST/Postgres com Supabase
├── models/
│   ├── item_record.dart                             # Modelo imutável ItemRecord, ItemStatus e limites
│   └── item_record_mapper.dart                      # Serialização/desserialização e validação de dados
├── state/
│   ├── item_form_controller.dart                    # Estado de submissão e novas tentativas do cadastro
│   ├── item_list_controller.dart                    # Estado de carregamento, sucesso e erro da listagem
│   └── operation_error_message.dart                 # Tradução segura de falhas para mensagens em português
└── ui/
    ├── routes.dart                                  # Constantes de rotas nomeadas
    ├── components/
    │   ├── empty_state.dart                         # Componente de lista vazia
    │   ├── item_record_card.dart                    # Cartão Material 3 de exibição de cada objeto
    │   └── list_feedback_state.dart                 # Componentes de carregamento e erro com retry
    ├── screens/
    │   ├── cadastro_screen.dart                     # Tela e formulário validado de cadastro
    │   └── listagem_screen.dart                     # Tela principal de listagem e atualização
    └── theme/
        └── app_theme.dart                           # Tema Material 3 da aplicação
supabase/
├── config.toml                                      # Configuração do projeto Supabase
└── migrations/
    └── 20261029120000_create_item_records.sql       # Criação da tabela item_records e políticas RLS
test/                                                # Testes unitários, de estado, de repositório e de widgets
```

---

## Pré-requisitos

- **Flutter SDK** `^3.13.5` (ou versão compatível com Dart 3 instalada no ambiente)
- Dispositivo Android/iOS, emulador configurado ou navegador compatível (ex.: Google Chrome)
- Conexão com a internet para comunicação com o banco em nuvem Supabase

---

## Instalação, Configuração e Execução

### 1. Clonar o repositório e instalar dependências

```bash
git clone https://github.com/Kaua-cel/pmob-aval2.git
cd pmob-aval2
flutter pub get
```

### 2. Parâmetros públicos de conexão com a nuvem

O aplicativo lê a URL pública do projeto e a chave pública (`publishable` / `anon` key) por meio de `--dart-define` na execução. Os parâmetros públicos do projeto configurado para avaliação são:

| Parâmetro | Valor Público |
| :--- | :--- |
| `SUPABASE_URL` | `https://mdkhjudazkkczbhcnzmd.supabase.co` |
| `SUPABASE_ANON_KEY` | `sb_publishable_fa0V3CNt0WqRJPWW5AUtRw_lfB6vbyU` |

> **Nota sobre segurança:** Estes são exclusivamente parâmetros públicos de cliente (`publishable`/`anon`), protegidos pelas políticas de Row Level Security (RLS) da tabela `public.item_records`. Nenhuma chave administrativa (`service_role`), senha de banco de dados ou credencial privada é utilizada pelo aplicativo ou versionada no repositório. O arquivo `.env.example` lista apenas os nomes dos parâmetros esperados.

Caso deseje provisionar uma instância própria do Supabase no plano gratuito, basta criar um projeto em [supabase.com](https://supabase.com) e executar o script [`supabase/migrations/20261029120000_create_item_records.sql`](supabase/migrations/20261029120000_create_item_records.sql) no **SQL Editor** (procedimento detalhado em [`docs/cloud-storage.md`](docs/cloud-storage.md)).

### 3. Executar o aplicativo (modo Release)

Por padrão, recomenda-se executar o aplicativo em **modo Release** (`--release`) para melhor desempenho em qualquer plataforma:

Em terminais Bash / macOS / Linux:

```bash
flutter run --release \
  --dart-define=SUPABASE_URL=https://mdkhjudazkkczbhcnzmd.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_fa0V3CNt0WqRJPWW5AUtRw_lfB6vbyU
```

No Windows (`cmd` — Prompt de Comando):

```cmd
flutter run --release ^
  --dart-define=SUPABASE_URL=https://mdkhjudazkkczbhcnzmd.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_fa0V3CNt0WqRJPWW5AUtRw_lfB6vbyU
```

Para executar no navegador Web (Google Chrome) em modo Release:

- **Bash / macOS / Linux:**
  ```bash
  flutter run --release -d chrome \
    --dart-define=SUPABASE_URL=https://mdkhjudazkkczbhcnzmd.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=sb_publishable_fa0V3CNt0WqRJPWW5AUtRw_lfB6vbyU
  ```
- **Windows (`cmd`):**
  ```cmd
  flutter run --release -d chrome ^
    --dart-define=SUPABASE_URL=https://mdkhjudazkkczbhcnzmd.supabase.co ^
    --dart-define=SUPABASE_ANON_KEY=sb_publishable_fa0V3CNt0WqRJPWW5AUtRw_lfB6vbyU
  ```

#### Opções adicionais de execução (modo Debug e seleção de dispositivo/navegador)

- **Executar em modo Debug:** basta remover a flag `--release` do comando (habilita *Hot Reload*, *Hot Restart* e inspeção de widgets):
  ```cmd
  flutter run ^
    --dart-define=SUPABASE_URL=https://mdkhjudazkkczbhcnzmd.supabase.co ^
    --dart-define=SUPABASE_ANON_KEY=sb_publishable_fa0V3CNt0WqRJPWW5AUtRw_lfB6vbyU
  ```
- **Alterar o dispositivo ou navegador (`-d <id-do-dispositivo>`):**
  1. Liste os dispositivos, emuladores e navegadores disponíveis na máquina com:
     ```cmd
     flutter devices
     ```
  2. Informe o identificador desejado com o parâmetro `-d`, por exemplo:
     - `-d chrome` (Google Chrome)
     - `-d edge` (Microsoft Edge)
     - `-d emulator-5554` (Emulador Android específico)
     - `-d <id-do-aparelho>` (Dispositivo físico conectado via USB)

---

## Validação e Testes Automatizados

O projeto conta com **53 testes automatizados** cobrindo modelos, mapeamento, repositório Supabase, controladores de estado, integração das telas, tratamento de falhas/retentativas e responsividade:

```bash
# 1. Verificar formatação do código
dart format .

# 2. Executar análise estática
flutter analyze

# 3. Executar suíte completa de testes automatizados
flutter test
```
