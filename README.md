# Garfada Log

**Nome do aluno:** Italo Beckman  
**Tema:** Controle de refeições: aplicativo para registrar as refeições feitas em ambientes comerciais.

---

## O que é o Garfadas Log? (Definições Gerais)

O **Garfadas Log** é um diário gastronômico interativo e totalmente offline, criado para ajudar o usuário a guardar e avaliar suas experiências em restaurantes, lanchonetes e bares.

Mais do que uma simples lista, o aplicativo atua como um juiz das suas experiências. Cada refeição registrada recebe uma avaliação em duas frentes fundamentais: **Custo-benefício** (peso de 40%) e **Qualidade da Comida** (peso de 60%). 

Com base nessas notas, o aplicativo calcula a média matemática e define automaticamente se o restaurante tem selo de aprovação (nota ≥ 3.5), carimbando o local com a métrica de que você **"Voltaria"** ou **"Não Voltaria"**. A recomendação é inteligente e consolidada, porém flexível: o usuário tem a liberdade de ajustar manualmente a recomendação se desejar intervir no sistema.

---

## Funcionalidades e Requisitos Funcionais

1.  **Catálogo de Restaurantes (CRUD Completo):** 
    - O aplicativo permite criar, listar, editar e deletar diversos restaurantes do seu histórico.
    - Cada cadastro identifica o *Nome do Local* e a sua categoria/*Tipo* (ex: Padaria, Pizzaria, etc.).

2.  **Registro de Pratos e Avaliações:**
    - O aplicativo atrela diversas refeições/pratos de maneira organizada a um mesmo restaurante criado.
    - No momento do cadastro da refeição, o usuário pontua o nível da comida e do custo-benefício em um slider de 0 a 5, salva o nome do prato saboreado e escreve observações extras.

3.  **Dashboards de Descoberta:**
    - **Área de Restaurantes:** Concentra todo o agrupamento dos locais visitados e seus vereditos em cards.
    - **Histórico Global de Refeições:** Reúne cada prato comido na vida do usuário em uma rolagem infinita independente do bar ou restaurante.
    - Oferece facilidade no gerenciamento com um sistema polido de exclusão em massa de pratos via múltipla-seleção.

4.  **Sistema de Filtros e Organizadores:**
    - O painel principal de locais traz abas interativas que filtram instantaneamente o que é exibido entre "Todos", somente os lugares que você "Voltaria", ou apenas as decepções que "Não Voltaria".
    - O histórico geral de pratos possui botão de classificação (Sort) rápido para elencar as *Melhores refeições da vida (Descendente)* ou os *Piores pratos (Ascendente)*.

5.  **Funcionamento Offline (Banco Relacional):**
    - Não depende de login, autenticação ou sequer internet. Todos os dados são propriedade sua dentro do seu próprio telefone, embutidos em SQLite. 
