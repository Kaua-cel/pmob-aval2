# Persistência em nuvem

## Serviço e limite de uso

O aplicativo usa **Supabase Postgres no plano Free**. Este fluxo não habilita cobrança,
cartão, autenticação ou recursos pagos. Antes de produção, confira limites e condições
atuais do provedor.

Leitura e escrita anônimas servem somente para registros demonstrativos. A chave `anon`
não substitui RLS e não impede abuso, spam ou leitura de dados que a política autorize.
Não armazene dados pessoais, sensíveis, fotos, anexos, localização precisa ou identidade do
dispositivo nesta tabela.

## Configuração do responsável

1. Crie um projeto no plano Free em Supabase.
2. Execute `supabase/migrations/20261029120000_create_item_records.sql` no SQL Editor ou
   aplique-a pela Supabase CLI.
3. Confirme que RLS está ativa em `public.item_records` e que existem somente as políticas
   `SELECT` e `INSERT` para `anon` definidas na migration.
4. Copie a URL HTTP(S) do projeto e a chave `anon` ou publishable para os `dart-defines` abaixo.

Execute o aplicativo assim, substituindo apenas no terminal local:

```sh
flutter run --dart-define=SUPABASE_URL=<project-url> --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

`SUPABASE_URL` e `SUPABASE_ANON_KEY` são valores públicos de cliente, protegidos por RLS.
Nunca versione, exiba em logs ou use no aplicativo: `service_role`, senha do banco, token
pessoal, chave administrativa ou `.env` local com valores reais. `.env.example` contém
somente nomes de variáveis e não é lido pelo aplicativo.

## Contrato remoto

Tabela: `public.item_records`.

| Coluna | Regra |
| --- | --- |
| `id` | UUID, chave primária, gerado pelo banco. |
| `name` | Texto obrigatório, máximo de 60 caracteres. |
| `description` | Texto obrigatório, máximo de 200 caracteres. |
| `location` | Texto obrigatório. |
| `status` | Somente `lost` ou `found`. |
| `created_at` | `timestamptz` UTC, preenchido pelo servidor com `now()`. |

O papel `anon` recebe apenas `SELECT` e `INSERT` nas colunas `name`, `description`,
`location` e `status`. A migration não concede `UPDATE` nem `DELETE`; por isso o cliente
não consegue definir `id` ou `created_at` na criação.

## Handoff para Issue 12

Use `ItemRecordRepository` para listar e criar objetos. `listItemRecords()` retorna
registros por `created_at` decrescente. `createItemRecord(draft)` envia somente `name`,
`description`, `location` e `status`; o retorno contém `id` e `createdAt` gerados pelo
servidor. Crie a instância real com `SupabaseItemRecordRepository.fromInitializedClient()`
depois da inicialização em `main`.

Validação manual entre instalações:

1. Inicie a primeira instalação com os mesmos dois `dart-defines` e crie um registro.
2. Confirme no Table Editor que `id` e `created_at` foram gerados pelo servidor.
3. Feche e reabra a primeira instalação; confirme a leitura do mesmo registro.
4. Inicie outra instalação com os mesmos `dart-defines`; confirme a leitura.
5. No SQL Editor ou cliente anônimo, confirme que `UPDATE` e `DELETE` são negados.
