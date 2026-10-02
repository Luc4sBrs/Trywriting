# 📋 TryWriting Kanban App

Um aplicativo moderno e profissional de gestão de tarefas no estilo **Kanban**, desenvolvido com **Flutter** e **Supabase**. O projeto foca em alta performance, sincronização em tempo real (*Realtime*), interface refinada com design monocromático e arquitetura escalável.

---

## 📸 Recursos e Funcionalidades

- **⚙️ Autenticação & Perfil de Usuário:**
  - Login e cadastro com gestão de sessão via Supabase Auth.
  - Perfil de usuário personalizável com **upload de foto de perfil (Avatar)** via Supabase Storage.

- **📌 Quadro Kanban Interativo:**
  - Organização de tarefas em colunas dinâmicas (*A Fazer*, *Em Progresso*, *Concluído*).
  - Movimentação fluida de tarefas com **Drag and Drop** (arrastar e soltar).
  - Categorização por prioridade (*Baixa*, *Média*, *Alta*) e definição de **datas de vencimento**.

- **⚡ Sincronização em Tempo Real (Realtime):**
  - Atualizações instantâneas de tarefas e status no quadro usando websockets via Supabase Realtime.
  - **Comentários em tempo real** nos cards de tarefas.

- **🎨 UX & Polimento Visual:**
  - Interface monocromática elegante com suporte a **Tema Claro e Escuro** (*Light/Dark Mode*).
  - **Skeleton Loaders (Shimmer)** para um carregamento suave de dados.
  - **Notificações Locais** agendadas no dispositivo para lembretes de tarefas prestes a vencer.

- **🔍 Pesquisa & Filtros Rápidos:**
  - Busca de tarefas por título ou descrição em tempo real.
  - Filtros rápidos por nível de prioridade.

- **📊 Dashboard de Desempenho:**
  - Métricas visuais e gráficos interativos (`fl_chart`) demonstrando a distribuição e saúde do projeto.

---

## 🛠️ Tecnogias e Ferramentas

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend / BaaS:** [Supabase](https://supabase.com/)
  - **Database:** PostgreSQL com Row Level Security (RLS)
  - **Auth:** Gerenciamento seguro de usuários
  - **Storage:** Buckets para armazenamento de avatares e anexos
  - **Realtime:** Inscrição em alterações no banco em tempo real
- **Gerenciamento de Estado / Padrões:** Controller Pattern / Native Streams
- **Pacotes Principais:**
  - `supabase_flutter`
  - `shimmer` (efeito de carregamento)
  - `flutter_local_notifications` (alertas locais)
  - `fl_chart` (gráficos de métricas)
  - `image_picker` (upload de imagens)

---

## 🚀 Como Executar o Projeto

### Pré-requisitos

- **Flutter SDK** instalado (versão 3.x ou superior)
- Um projeto ativo no **Supabase**

### 1. Clonar o repositório

```bash
git clone [https://github.com/seu-usuario/nome-do-repositorio.git](https://github.com/seu-usuario/nome-do-repositorio.git)
cd nome-do-repositorio