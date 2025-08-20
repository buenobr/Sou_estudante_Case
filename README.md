# Sou Estudante

O aplicativo **Sou Estudante** foi desenvolvido em **Flutter** e é uma plataforma colaborativa para que estudantes possam encontrar e compartilhar promoções, descontos e ofertas especiais. Ele se destaca por ter funcionalidades de moderação por administradores, garantindo que o conteúdo seja relevante e de alta qualidade para a comunidade.

A aplicação utiliza o ecossistema do **Google Firebase** para gerenciar dados, autenticação de usuários e armazenamento, e integra o **Google AdMob** para monetização.

---

## Como Funciona

A plataforma opera com base na colaboração da comunidade e na moderação dos administradores:

-   **Contribuição da Comunidade**: Usuários autenticados podem enviar novas promoções, fornecendo informações como título, link, preço e categoria. Um sistema de pré-visualização de links ajuda a preencher dados automaticamente.
-   **Moderação de Conteúdo**: Todas as promoções submetidas são enviadas para aprovação de um administrador. Os administradores têm acesso a telas específicas para aprovar, editar ou deletar promoções pendentes.
-   **Visualização de Promoções**: A tela principal exibe as promoções aprovadas, organizadas por categorias, e permite que os usuários busquem por ofertas específicas.
-   **Recursos Adicionais**: A aplicação oferece funcionalidades como a possibilidade de favoritar promoções, reportar problemas em ofertas e gerenciar as próprias configurações de conta, como alteração de senha.

---

## Componentes do Projeto

O projeto está organizado da seguinte forma:

-   `lib/main.dart`: O ponto de entrada da aplicação. Ele configura o Firebase, o Google AdMob, e gerencia a navegação inicial com o `AuthGate`, que direciona o usuário para a tela de verificação de e-mail ou para a tela principal com base no seu status de autenticação.
-   `lib/login_screen.dart`: Permite que os usuários façam login com e-mail e senha ou com a conta Google, além de criar novas contas e documentos de usuário no Firestore.
-   `lib/home_screen.dart`: A tela principal da aplicação. Exibe as promoções, permite a filtragem por categoria e a busca por palavras-chave. Também exibe anúncios do AdMob e fornece acesso a outras telas, como a de favoritos e as telas de administração.
-   `lib/add_promotion_screen.dart`: Formulário para submissão de novas promoções pelos usuários, incluindo validação de campos e funcionalidade para buscar dados a partir de um link.
-   `lib/promotion_detail_screen.dart`: Exibe os detalhes de uma promoção específica. Permite que os usuários reajam com "curtir" ou "não curtir", adicionem comentários e reportem problemas.
-   `lib/admin_approval_screen.dart`: Tela para administradores visualizarem e gerenciarem promoções pendentes. Eles podem aprovar ou deletar as ofertas.
-   `lib/admin_reports_screen.dart`: Tela exclusiva para administradores gerenciarem os problemas reportados pelos usuários nas promoções.
-   `lib/app_colors.dart`: Define a paleta de cores da aplicação, com opções para os modos claro e escuro.
-   `lib/theme_manager.dart`: Gerencia o tema do aplicativo, permitindo que o usuário escolha entre os modos "Claro", "Escuro" ou "Seguir Sistema" e salva a preferência localmente.

---

## Estrutura do Banco de Dados (Firestore)

A aplicação utiliza o **Firestore**, um banco de dados NoSQL, com as seguintes coleções principais:

### `promotions`
Armazena os dados de cada promoção.
-   `title`: Título da promoção.
-   `description`: Descrição detalhada.
-   `link`: URL da oferta.
-   `imageUrl`: URL da imagem do produto.
-   `priceValue`: O valor numérico da promoção (preço ou porcentagem).
-   `priceType`: O tipo do valor (monetário ou porcentagem).
-   `category`: Categoria da promoção (ex: 'Software', 'Cursos').
-   `status`: Status da promoção (pending, approved, deleted).
-   `likedBy`: Uma lista de IDs de usuários que curtiram a promoção.
-   `dislikedBy`: Uma lista de IDs de usuários que não gostaram da promoção.
-   `submittedBy`: ID do usuário que submeteu a promoção.

### `users`
Armazena informações dos usuários.
-   `email`: E-mail do usuário.
-   `uid`: ID único do usuário.
-   `role`: Nível de permissão do usuário (user ou admin).
-   `favorites`: Uma lista de IDs das promoções favoritas do usuário.

### `reports`
Armazena os problemas reportados pelos usuários.
-   `promotionId`: ID da promoção com problema.
-   `promotionTitle`: Título da promoção.
-   `problemDescription`: Descrição do problema.
-   `status`: Status do reporte (pending, resolved, ignored).
-   `reportedByUserId`: ID do usuário que reportou.
-   `reportedByUserEmail`: E-mail do usuário que reportou.

---

## Como Usar o Projeto (Ambiente Local)

Para configurar e rodar o projeto localmente, siga estes passos.

### Pré-requisitos
-   **Flutter SDK** instalado e configurado.
-   Conexão com a internet.
-   Conta e projeto no **Firebase**.

### Passo a Passo

1.  **Clone o Repositório**: Abra seu terminal e clone o projeto:
    ```bash
    git clone [URL_DO_REPOSITORIO]
    cd sou_estudante
    ```

2.  **Instale as Dependências**: No terminal, dentro da pasta do projeto, execute:
    ```bash
    flutter pub get
    ```

3.  **Configure o Firebase**: A aplicação depende do Firebase para funcionar. Siga estas instruções para configurar:
    -   **Crie um Projeto no Firebase**: Vá para o [Console do Firebase](https://console.firebase.google.com/) e crie um novo projeto.
    -   **Configure o FlutterFire**: Siga as instruções oficiais do FlutterFire para instalar a CLI e configurar seu projeto: [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup).
    -   **Gere o arquivo `firebase_options.dart`**: Execute o seguinte comando no terminal do seu projeto:
        ```bash
        flutterfire configure
        ```
    -   **Modifique o `firebase_options.dart` (opcional)**: O projeto já vem com um arquivo `lib/MODIFICAR_firebase_options.dart` que você pode usar como base. Simplesmente renomeie-o para `firebase_options.dart` e substitua os valores (`apiKey`, `appId`, etc.) com os do seu próprio projeto Firebase.

4.  **Configure o Google AdMob**:
    -   Vá ao [Console do Google AdMob](https://admob.google.com/home/).
    -   Crie um aplicativo e uma unidade de anúncio de banner.
    -   Substitua os IDs de anúncios de teste no arquivo `lib/ad_helper.dart` pelos IDs reais da sua conta.

5.  **Configure as Regras do Firestore**: Para que a aplicação funcione corretamente, você precisa definir as regras de segurança no Firestore. Vá ao console do Firebase > **Firestore Database** > **Regras**.

    ```firestore
    // Exemplos de regras de segurança
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        match /promotions/{promoId} {
          allow read;
          // Regras de escrita, atualização e deleção para usuários e admins
        }

        match /users/{userId} {
          allow read: if request.auth.uid != null;
          allow create;
          allow update: if request.auth.uid == userId;
        }

        match /reports/{reportId} {
          allow create: if request.auth.uid != null;
          // Apenas admins podem ler ou atualizar
        }
      }
    }
    ```

6.  **Execute o Aplicativo**: Com todas as configurações feitas, você pode executar o aplicativo no seu dispositivo ou emulador preferido.
    ```bash
    flutter run
    ```