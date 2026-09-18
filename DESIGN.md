# Design System: Meliponicultura iOS / Apple Experience

Este documento define os princípios de design, paleta visual, tipografia, componentes e diretrizes de interação para o aplicativo de **Monitoramento Inteligente de Colmeias de Abelhas Sem Ferrão (Meliponicultura)**.

---

## 1. Princípios de Design & Atmosfera Visual

Inspirado na precisão, clareza e elegância do ecossistema Apple/iOS, o aplicativo equilibra **rigor técnico de telemetria IoT** com uma **experiência acolhedora, amigável e biofílica**.

- **Clareza e Respiração:** Telas limpas, espaçamento em escala de 4pt/8pt, superfícies translúcidas e hierarquia visual evidente.
- **Glassmorphism Sutil:** Superfícies translúcidas com efeito de desfoque (`BackdropFilter` com `ImageFilter.blur`), bordas com iluminação foscada e sombras suaves (4% a 8% de opacidade).
- **Mascote Vivo e Empático:** Uma abelha sem ferrão com micro-animações nativas, reagindo em tempo real ao bem-estar do enxame (feliz na faixa ideal de 26°C a 32°C; atenta/preocupada em temperaturas anômalas).
- **Sensação Tátil:** Resposta tátil a toques, micro-animações de escala no clique de botões e transições fluidas com `Hero` entre o dashboard e as colmeias individuais.

---

## 2. Paleta de Cores e Papéis Semânticos

### Cores Primárias e Marca
- **Lake Blue** (`#0072CE`): Cor de ação principal, botões de destaque, anéis de progresso ativos e abas selecionadas.
- **Deep Navy** (`#005DAA`): Tom de suporte para cabeçalhos e contrastes nobres.
- **Sky Blue Tint** (`#E7F0FF`): Fundo suave de chips informativos e elementos destacados secundários.
- **Honey Amber** (`#F59E0B`): Acento melífero complementar para espécies e alertas moderados.

### Saúde Térmica & Status Biológico
- **Ideal / Confortável (26°C a 32°C)**: `#19C37D` (Verde Esmeralda Vibrante) — Enxame em homeostase ideal.
- **Atenção / Limítrofe (24°C–26°C ou 32°C–35°C)**: `#F59E0B` (Âmbar) — Variação térmica exigindo atenção.
- **Crítico (< 24°C ou > 35°C)**: `#EF4444` (Vermelho Alerta) — Risco biológico para a colônia (perda de cria ou superaquecimento).

### Conectividade ESP32 IoT
- **Online / Conectado**: `#10B981` com halo pulsante de brilho suave.
- **Offline / Sem Sinal**: `#9CA3AF` ou `#DC2626`.

### Superfícies e Tipografia
- **Canvas White**: `#FFFFFF` / Fundo Claro `#F8FAFC`.
- **Glass Surface**: `rgba(255, 255, 255, 0.75)` com desfoque de 15px e borda `rgba(255, 255, 255, 0.6)`.
- **Text Ink**: `#1F2937` (Texto principal de alta legibilidade).
- **Text Slate**: `#4B5563` (Texto secundário e legendas).
- **Text Mute**: `#9CA3AF` (Placeholders e indicadores inativos).

---

## 3. Tipografia e Numerais Tabulares

- **Família Tipográfica**: SF Pro / Cupertino Fonts nativas com fallback geométrico sans-serif.
- **Numerais Tabulares**: Todos os dados numéricos de telemetria (temperatura `28.4°C`, fluxo `42 ab/min`, umidade `68%`) utilizam numerais alinhados e pesos bem definidos (Medium 500, SemiBold 600, Bold 700).
- **Escala de Tamanhos**:
  - Hero Number (Temperatura principal): 44pt - 52pt Bold.
  - Títulos de Seção / Nav Bar: 20pt - 26pt SemiBold.
  - Nomes de Colmeia & Métricas: 16pt - 18pt SemiBold.
  - Subtítulos & Espécies: 13pt - 14pt Regular/Medium.
  - Legendas de Rodapé: 11pt - 12pt Medium em caixa alta com letter-spacing suave.

---

## 4. Componentes Chave

1. **Card de Colmeia (Dashboard)**:
   - Raio de canto: 20pt.
   - Efeito Glassmorphism com borda translúcida.
   - Badge animado com ponto pulsante para Wi-Fi SoftAP ESP32.
   - Tag de espécie com destaque sutil.
   - Mini-resumo de temperatura e fluxo de tráfego.
   - Transição `Hero` unindo o card ao painel de detalhes.

2. **Mascote da Abelha Sem Ferrão (Micro-animações)**:
   - Animação de bater de asas contínuo e suave.
   - Olhos expressivos e sorriso amigável quando em faixa térmica ideal (26°C a 32°C).
   - Expressão de alerta com bochechas expressivas e movimento de dúvida se a temperatura estiver fora do padrão.

3. **Alternador de Mídia (Cupertino Segmented Control)**:
   - Segmentos: "Ao Vivo (Vídeo)" vs "Galeria de Registros".
   - Limpeza visual sem sobrecarregar a tela com múltiplos streams ao mesmo tempo.

4. **Formulários Agrupados no Estilo iOS**:
   - Campos de formulário com fundo cinza suave (`#F3F4F6`), cantos arredondados (12pt), divisores finos e ícones `CupertinoIcons`.

