========================================================
SCREENPIN – DESKTOP PER MONITOR (WINDOWS 11)
Simulação de Desktop Virtual Independente por Monitor
========================================================

📌 VISÃO GERAL

O ScreenPin (anteriormente Desktop Per Monitor) é uma solução avançada para contornar a limitação dos Desktops Virtuais do Windows 11, onde a troca de desktop afeta todos os monitores globalmente.

Diferente de soluções baseadas em "Pinagem" de janelas (que podem ser instáveis em versões recentes do Windows como a 25H2), este projeto utiliza uma técnica de **migração instantânea de janelas**. 

O resultado é a simulação perfeita de que um monitor está "fixo" enquanto os outros alternam livremente entre desktops virtuais, sem janelas presas ou resíduos no sistema.

--------------------------------------------------------
🎯 A NOVA ESTRATÉGIA (MOVIMENTAÇÃO DIRETA)
--------------------------------------------------------

A lógica foi evoluída para garantir 100% de compatibilidade e performance:

1.  **Monitor Fixo:** Você escolhe qual monitor deve manter suas janelas estáticas.
2.  **Migração Pré-Troca:** No exato milissegundo antes de mudar o desktop, o script identifica as janelas no monitor fixo e as move para o desktop de destino.
3.  **Transição Transparente:** O Windows muda de desktop, mas como as janelas do monitor fixo "já estão lá", elas parecem nunca ter saído do lugar.

Essa abordagem é muito mais robusta para janelas UWP (Calculadora, Configurações, Terminal) e evita bugs de foco.

--------------------------------------------------------
🧠 RECURSOS TÉCNICOS
--------------------------------------------------------

✔ **Seleção Inteligente:** Interface gráfica (GUI) moderna para escolher o monitor fixo no início.
✔ **Detecção Geométrica:** Usa coordenadas geográficas (X, Y) para identificar janelas, garantindo precisão mesmo em monitores com diferentes escalas (DPI).
✔ **Alta Compatibilidade:** Funciona com janelas Win32 tradicionais e aplicativos modernos (UWP).
✔ **Sem Resíduos:** Não altera registros do Windows nem deixa janelas "pinadas" permanentemente.

--------------------------------------------------------
🎮 ATALHOS (HOTKEYS)
--------------------------------------------------------

O ScreenPin substitui/estende os atalhos nativos do Windows para garantir a lógica de monitor fixo:

- **Ctrl + Win + → / ↑**  → Próximo Desktop (Direita)
- **Ctrl + Win + ← / ↓**  → Desktop Anterior (Esquerda)
- **Ctrl + Win + Mouse4** → Próximo Desktop
- **Ctrl + Win + Mouse5** → Desktop Anterior
- **Ctrl + Win + Delete** → Reiniciar o Script (Voltar à tela de seleção)

--------------------------------------------------------
🖥️ REQUISITOS E DEPENDÊNCIAS
--------------------------------------------------------

- **AutoHotkey v2.0+**
- **VirtualDesktopAccessor.dll** (Inclusa no projeto)
- **Windows 11** (Testado e otimizado para as builds mais recentes, incluindo 25H2)

O projeto depende da DLL `VirtualDesktopAccessor` de autoria de **Ciantic**, que fornece a ponte necessária com as APIs internas de Desktop Virtual do Windows.

--------------------------------------------------------
⚠️ NOTA DE PERFORMANCE
--------------------------------------------------------

O script foi otimizado para realizar a migração de janelas de forma assíncrona e imediata, minimizando qualquer "flicker" visual. Para melhor experiência, recomenda-se desativar as animações de troca de desktop nas configurações de acessibilidade do Windows se você busca uma transição instantânea.

--------------------------------------------------------
📌 CONCLUSÃO
--------------------------------------------------------

O ScreenPin entrega a funcionalidade mais requisitada por usuários de múltiplos monitores: a capacidade de manter o fluxo de trabalho fixo em uma tela enquanto explora diferentes contextos nas outras. Simples, robusto e essencial para produtividade avançada.
