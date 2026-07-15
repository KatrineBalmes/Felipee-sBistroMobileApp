# Filipee's Bistro — POS & Inventory Management (Flutter)

A Flutter rebuild of the original CustomTkinter desktop system for **Filipee's Bistro**
(Poblacion Branch, Bauan, Batangas). Built for **IT 331 — Application Development and
Emerging Technologies**.

Rebuilt from the original Python/CustomTkinter desktop app (`login.py`, `cashier_app.py`,
`owner_app.py`, `filipees_bistro.db`) into a single cross-platform Flutter application, plus
a brand-new public **landing page**.

## ✨ What's new vs. the desktop version

- **Public landing page** — hero section, brand story, live menu highlights, photo gallery,
  and a contact/location section, all before any login is required.
- Fully responsive layout: `NavigationRail`-style side menu on tablets/desktop, bottom
  navigation bar on phones.
- Same role-based access model (Owner vs. Cashier) and the same local SQLite schema as the
  original desktop app, so existing data concepts map 1:1.

## 📱 Screens

| Section | Access | Description |
|---|---|---|
| Landing Page | Public | Hero, About, Menu highlights, Gallery, Contact & Location, Footer |
| Login | Public | Username/password auth against local SQLite `users` table |
| Point of Sale | Cashier, Owner | Category-filtered menu grid, live cart, order type & payment method, receipt |
| Inventory | Cashier (view-only), Owner (full CRUD) | Menu items + raw ingredients, low-stock alerts, stock status pills |
| Dashboard | Owner | Today's sales/orders, low-stock alerts, recent orders |
| Sales Monitor | Owner | Daily sales bar chart + full transaction history |
| AI Forecast | Owner | Rule-based 7-day moving-average demand engine — classifies each item as Increasing / Stable / Decreasing and flags sales anomalies |
| Users | Owner | Add/remove cashier accounts, reset passwords |

## 🗂️ Project structure

```
lib/
  main.dart                      # App entry point
  theme/app_theme.dart           # Colors, typography, component themes
  models/models.dart             # MenuItem, Ingredient, CartItem, SaleTransaction, AppUser
  data/db_helper.dart            # sqflite persistence + seed data
  widgets/
    common_widgets.dart          # BistroCard, GradientButton, StatusPill, etc.
    app_shell.dart                # Responsive nav shell (rail / bottom bar)
  screens/
    landing/landing_screen.dart  # Public marketing page
    auth/login_screen.dart
    shared/pos_page.dart         # Shared by cashier & owner
    shared/inventory_page.dart   # canEdit flag toggles view-only vs CRUD
    cashier/cashier_shell.dart
    owner/{owner_shell, dashboard_page, sales_page, forecast_page, users_page}.dart
assets/images/                   # Logo + gallery photos
```

## 🔑 Demo accounts

| Role | Username | Password |
|---|---|---|
| Owner | `owner` | `owner123` |
| Cashier | `cashier` | `cashier123` |

(Tap the "Owner demo" / "Cashier demo" chips on the login screen to autofill.)

## 🧰 Tech stack

- **Flutter** (Material 3, dark theme)
- **sqflite** — local relational storage, schema mirrors the original `filipees_bistro.db`
- **fl_chart** — Sales Monitor bar chart
- **url_launcher** — Facebook / Instagram / phone / Maps deep links
- **google_fonts** — Playfair Display (headings) + Plus Jakarta Sans (body)

## ▶️ Getting started

```bash
flutter pub get
flutter run
```

## 📍 Business info

- **Address:** 1013 Ylagan St. Poblacion 4, Bauan, Batangas, Philippines, 4204
- **Phone:** 0956 544 5021
- **Facebook:** [facebook.com/filipeesbistro](https://www.facebook.com/filipeesbistro)
- **Instagram:** [@filipees_bistro](https://www.instagram.com/filipees_bistro)

## 🎯 Data handling & AI Forecast note

All data is stored locally via `sqflite` (menu items, ingredients, transactions, users),
seeded on first launch with sample data equivalent to the original desktop database. The
**AI Forecast** page implements the rule-based demand engine described in the project
proposal: it computes a 7-day moving average of units sold per menu item, compares it to
the prior 7-day window, and classifies the trend using a ±10% threshold rule — surfacing a
procurement recommendation and flagging anomalously low-demand items.
