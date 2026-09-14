# NexServ 

A multi-role Flutter application built to manage and streamline cooperative gig services. 

NexServ provides a unified ecosystem for three distinct user roles—Customers, Workers, and Administrators—operating from a single codebase with centralized state management. The platform is designed to handle job matching, real-time metrics tracking, secure verification flows, and accessibility requirements.

## Architecture & Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** Provider (`MultiProvider`, `ChangeNotifier`) for reactive cross-role data synchronization.
- **Routing:** Centralized named routing via `AppRoutes` and `NavigatorKey` for context-less navigation.
- **Design System:** Material 3 with fully responsive constraints (`IntrinsicHeight`, `Flexible`).

## Core Features

### 1. Unified Multi-Role Environment
- **Worker Portal:** Features simulated AI-driven demand heatmaps for surge zones, job acceptance flows, and transparent billing generation with automated welfare pool deductions.
- **Customer Portal:** Modern interface for service booking, dynamic category rendering, and simulated real-time map tracking.
- **Admin Dashboard:** Live oversight panel tracking active verified workers, daily gross platform volume, and cooperative welfare funds.

### 2. State Synchronization
- Built with a reactive global state architecture where actions performed in one role (e.g., a customer booking a service) immediately trigger state updates across other roles (e.g., incoming job alerts for workers, incrementing financial metrics for admins).

### 3. Security & Validation
- **Strict Form Validation:** Implemented RegEx-based formatters for name, phone number, and worker ID fields during the registration flow.
- **Service Hand-offs:** Features an OTP-locked verification flow requiring workers to input a customer-provided 4-digit code before initiating a service timer.

### 4. Accessibility (a11y)
- **Dynamic Localization:** Real-time toggling between English and Hindi across the entire application interface.
- **Voice Assistance:** Simulated voice-prompt integrations to assist low-literacy users in navigating the UI.

## Local Setup

To run this project locally:

```bash
git clone https://github.com/DigvijayParade/NexServ.git
cd NexServ
flutter pub get
flutter run
```
