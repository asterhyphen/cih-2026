# AGENTS

- Keep business logic in providers and logic files; avoid putting feature behavior directly in widgets.
- Keep files compact and split by responsibility so they stay under roughly 150 lines when practical.
- Follow the shared glass UI conventions from core/theme/glass_style.dart and core/theme/app_theme.dart.
- Add new feature logic inside the existing feature folder unless a genuinely new capability needs a new top-level feature area.
- Mock transport and chaos-simulation logic lives in lib/features/transmission_engine/logic and is driven by lib/features/network_simulator/providers; extend those files instead of adding transport behavior directly to widgets.
