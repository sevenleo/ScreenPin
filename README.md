========================================================
DESKTOP PER MONITOR – WINDOWS 11
Simulação de Desktop Virtual Independente por Monitor
========================================================

📌 VISÃO GERAL

O Desktop Per Monitor é um projeto que contorna uma limitação estrutural do
Windows 10/11: os desktops virtuais são globais e, por padrão, afetam todos
os monitores simultaneamente.

Este projeto implementa uma solução sólida e transparente que SIMULA
desktops virtuais independentes por monitor, criando a experiência de que:

- Qualquer monitor pode permanecer fixo
- Os demais monitores alternam de desktop normalmente
- Ou, se desejado, nenhum monitor permanece fixo

Tudo isso acontece sem mover janelas manualmente, sem alterar configurações
do sistema operacional e sem deixar resíduos após o uso.

O resultado é um ambiente de trabalho muito mais flexível, previsível e
produtivo para setups multi-monitor.

--------------------------------------------------------
🎯 IDEIA POR TRÁS DO PROJETO
--------------------------------------------------------

O conceito central do projeto é explorar corretamente os mecanismos nativos
do próprio Windows, respeitando seus limites reais.

A abordagem consiste em:

✔ Utilizar o sistema de PIN de janelas do Windows  
✔ Aplicar o PIN apenas no momento exato da troca de desktop  
✔ Liberar todas as janelas automaticamente após a transição  

Dessa forma, o Windows mantém as janelas do monitor escolhido visíveis
durante a troca de desktop, mas nenhuma janela permanece presa fora desse
intervalo crítico.

O comportamento é limpo, reversível e livre de efeitos colaterais.

--------------------------------------------------------
🧠 COMO FUNCIONA (RESUMO TÉCNICO)
--------------------------------------------------------

1. O script inicia e solicita ao usuário qual monitor deve permanecer fixo
   (ou se nenhum monitor deve ser fixado)
2. A escolha é feita por meio de uma interface gráfica simples, com botões
   numerados correspondentes aos monitores identificados pelo Windows
3. Durante o uso:
   - Ao acionar um atalho, o script identifica as janelas do monitor fixo
   - Essas janelas são pinadas temporariamente
   - O desktop virtual é alterado
   - Após o commit real do desktop, todas as janelas são despinadas
4. Resultado visual:
   - Apenas os monitores livres aparentam trocar de desktop
   - O monitor fixo permanece estável e contínuo

Nenhuma janela fica pinada permanentemente.

--------------------------------------------------------
🚀 PRINCIPAIS RECURSOS
--------------------------------------------------------

✔ Simulação de desktops independentes por monitor  
✔ Escolha dinâmica do monitor fixo ao iniciar  
✔ Opção de não fixar nenhum monitor  
✔ Interface gráfica leve e imediata para seleção  
✔ Suporte a múltiplos monitores (2 ou mais)  
✔ Alternância de desktop confiável via atalhos personalizados  
✔ Pinagem estritamente temporária e controlada  
✔ Reset completo do script via atalho dedicado  
✔ Limpeza total de estado ao encerrar ou reiniciar  
✔ Funcionamento transparente e reversível  

--------------------------------------------------------
🎮 ATALHOS SUPORTADOS
--------------------------------------------------------

- Ctrl + Win + ↑   → alternar desktop
- Ctrl + Win + ↓   → alternar desktop
- Ctrl + Win + Mouse4
- Ctrl + Win + Mouse5
- Ctrl + Win + Delete → resetar o script e voltar à tela de seleção

Todos os atalhos utilizam a mesma lógica interna, garantindo comportamento
consistente em qualquer forma de acionamento.

--------------------------------------------------------
🖥️ CASOS DE USO REAIS
--------------------------------------------------------

✔ Desenvolvedores:
  - Código alternando entre desktops
  - Documentação, terminal ou browser sempre visíveis em um monitor fixo

✔ Streamers e criadores de conteúdo:
  - OBS, chat e painéis de controle estáticos
  - Jogos ou aplicações alternando de desktop

✔ Profissionais e analistas:
  - Dashboards, planilhas e monitoramento contínuo
  - Área principal livre para alternar tarefas

✔ Produtividade avançada:
  - Um ou mais monitores estáveis
  - Um ambiente de trabalho dinâmico e organizado

--------------------------------------------------------
⚠️ LIMITAÇÕES (HONESTIDADE TÉCNICA)
--------------------------------------------------------

- O Windows não oferece desktops independentes nativos por monitor
- Este projeto é uma simulação inteligente, não um recurso oficial
- A animação de troca de desktop ainda ocorre em todos os monitores
- Algumas aplicações UWP podem ignorar o pin de janelas

Apesar disso, esta é a abordagem mais próxima, funcional e estável possível
dentro das limitações reais do sistema operacional.

--------------------------------------------------------
🧩 TECNOLOGIA UTILIZADA
--------------------------------------------------------

- AutoHotkey v2
- Windows API (MonitorFromWindow, EnumDisplayMonitors)
- Virtual Desktop COM API (acesso indireto)

🔗 DLL FUNDAMENTAL DO PROJETO  
VirtualDesktopAccessor  
Autor: Ciantic  

Repositório oficial:
https://github.com/Ciantic/VirtualDesktopAccessor

Essa DLL fornece os mecanismos necessários para:
- Alternar desktops virtuais
- Pinar e despinar janelas
- Interagir com a API interna de desktops do Windows

Este projeto é construído sobre essa base e não seria possível sem ela.

--------------------------------------------------------
🛡️ SEGURANÇA, CONTROLE E LIMPEZA
--------------------------------------------------------

✔ Nenhuma janela permanece pinada fora do uso  
✔ Reset completo disponível a qualquer momento  
✔ Encerramento garante limpeza total do estado  
✔ Nenhum serviço, tarefa agendada ou processo oculto  
✔ Execução restrita ao tempo de vida do script  

--------------------------------------------------------
📈 POSSÍVEIS EVOLUÇÕES
--------------------------------------------------------

- Salvamento automático da escolha do monitor
- Troca de monitor fixo em tempo real
- Suporte a múltiplos monitores fixos simultaneamente
- Overlays visuais de indicação
- Interface de bandeja (tray)
- Versão em C# ou serviço dedicado

--------------------------------------------------------
📌 CONCLUSÃO
--------------------------------------------------------

O Desktop Per Monitor não tenta substituir o Windows nem forçar comportamentos
não suportados. Ele trabalha dentro das regras do sistema, explorando os
pontos corretos de controle para entregar uma experiência que o próprio
Windows ainda não oferece nativamente.

Para quem utiliza múltiplos monitores e desktops virtuais, o ganho em
organização, previsibilidade e produtividade é imediato.

Simples, consistente, reversível e eficiente.
========================================================