# Checklist de Correção - ScreenPin (Windows 11 25H2)

## ✅ Fase 1: Implementação da Movimentação Direta
- [x] Implementar detecção de coordenadas de monitor via `MonitorGet`.
- [x] Corrigir `IsWindowOnFixedMonitor` para usar coordenadas geográficas (X, Y).
- [x] Modificar `ToggleDesktop` para usar `MoveWindowToDesktopNumber` antes de mudar o desktop.
- [x] Validar se as janelas UWP (Calculadora, Configurações) acompanham a troca. (Confirmado: Funcionando via DLL)

## 🎨 Fase 2: Polimento e UI
- [x] Limpeza de código duplicado e refatoração de funções de GUI.
- [x] Ajustar layout da janela de escolha para melhor centralização e estética.
- [x] Atualização completa do README.md com a nova lógica de movimentação.

## 🔄 Fase Opcional: Futuras Melhorias
- [ ] Adicionar suporte a múltiplos monitores fixos simultaneamente.
- [ ] Implementar menu na bandeja (System Tray) para troca rápida de monitor fixo.
- [ ] Persistência de configuração (Salvar monitor fixo entre reinicializações).
- [ ] Logs de erro via `OutputDebug` para monitorar retornos da DLL em tempo real.