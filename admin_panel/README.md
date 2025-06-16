# Bitcoin Cloud Mining Admin Panel

This is the admin panel for the Bitcoin Cloud Mining application. It provides a comprehensive dashboard for administrators to manage users, monitor transactions, handle withdrawal requests, and view system notifications.

## Features

- **Admin Authentication**: Secure login system for administrators
- **Dashboard**: Overview of key metrics and recent activities
- **User Management**: View and manage user accounts
- **Transaction Monitoring**: Track all transactions in the system
- **Withdrawal Management**: Review and approve/reject withdrawal requests
- **Notification System**: System-wide notifications for important events

## Getting Started

### Prerequisites

- Flutter SDK (2.17.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / VS Code with Flutter extensions
- An emulator or physical device for testing

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/your-username/bitcoin_mining_admin.git
   ```

2. Navigate to the project directory:
   ```
   cd bitcoin_mining_admin
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Create a `.env` file in the root directory with the following variables:
   ```
   API_BASE_URL=https://your-api-domain.com/api
   ```

5. Run the application:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── config/
│   └── api_config.dart
├── models/
│   ├── user_model.dart
│   └── transaction_model.dart
├── screens/
│   ├── login_screen.dart
│   ├── admin_dashboard.dart
│   ├── admin_notifications_screen.dart
│   ├── admin_withdraw_screen.dart
│   ├── users_screen.dart
│   └── user_details_screen.dart
├── services/
│   └── api_service.dart
├── utils/
│   └── storage_utils.dart
├── widgets/
│   ├── admin_drawer.dart
│   └── dashboard_card.dart
└── main.dart
```

## Configuration

The application uses environment variables for configuration. Create a `.env` file in the root directory with the following variables:

```
API_BASE_URL=https://your-api-domain.com/api
```

## Building for Production

To build the application for production, run:

```
flutter build apk --release
```

For iOS:

```
flutter build ios --release
```

## Security

This admin panel implements several security measures:

- Secure token-based authentication
- Automatic session timeout
- Input validation and sanitization
- Secure storage of sensitive information

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors who have helped improve this project 