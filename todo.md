# Checklist de Correção - ScreenPin (Windows 11 25H2)

## 🛠️ Fase 1: Opção 2 (Movimentação Direta)
- [x] Implementar detecção de coordenadas de monitor via `MonitorGet`.
- [x] Corrigir `IsWindowOnFixedMonitor` para usar coordenadas geográficas (X, Y).
- [x] Modificar `ToggleDesktop` para usar `MoveWindowToDesktopNumber` antes de mudar o desktop.
- [ ] Validar se as janelas UWP (Calculadora, Configurações) acompanham a troca.

## 🔄 Fase 2: Plano de Fallback (Opção 1)
- [ ] Caso a Opção 2 falhe: Reintroduzir `EnumDisplayMonitors` com callback AHK v2.
- [ ] Tentar forçar `PinApp` (Pinagem por App) ao invés de `PinWindow` se a 25H2 preferir.
- [ ] Adicionar logs de erro via `OutputDebug` para monitorar retornos da DLL.
