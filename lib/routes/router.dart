import 'package:due_kasir/pages/customer.dart';
import 'package:due_kasir/pages/customer/customer_form.dart';
import 'package:due_kasir/pages/due_payment.dart';
import 'package:due_kasir/pages/due_payment/due_payment_form.dart';
import 'package:due_kasir/pages/expenses.dart';
import 'package:due_kasir/pages/home.dart';
import 'package:due_kasir/pages/inventory.dart';
import 'package:due_kasir/pages/inventory/csv_preview.dart';
import 'package:due_kasir/pages/inventory/inventory_form.dart';
import 'package:due_kasir/pages/login.dart';
import 'package:due_kasir/pages/presence.dart';
import 'package:due_kasir/pages/register.dart';
import 'package:due_kasir/pages/rent.dart';
import 'package:due_kasir/pages/rent/rent_item_form.dart';
import 'package:due_kasir/pages/report.dart';
import 'package:due_kasir/pages/request.dart';
import 'package:due_kasir/pages/request/request_form.dart';
import 'package:due_kasir/pages/salaries.dart';
import 'package:due_kasir/pages/low_stock_report.dart';
import 'package:due_kasir/pages/salaries/salaries_form.dart';
import 'package:due_kasir/pages/selling.dart';
import 'package:due_kasir/pages/selling/print_setting.dart';
import 'package:due_kasir/pages/store.dart';
import 'package:due_kasir/pages/sync.dart';
import 'package:due_kasir/pages/testing.dart';
import 'package:due_kasir/pages/audit_logs.dart';
import 'package:due_kasir/pages/users.dart';
import 'package:due_kasir/pages/users/user_form.dart';
import 'package:due_kasir/pages/bills/pending_receipts.dart';
import 'package:due_kasir/pages/bills/printed_bills.dart';
import 'package:due_kasir/pages/inventory/inventory_history.dart';
import 'package:due_kasir/pages/store/database_health.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'router.g.dart';

@TypedGoRoute<LowStockReportRoute>(path: '/low-stock-report')
class LowStockReportRoute extends GoRouteData {
  const LowStockReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LowStockReportScreen();
}

@TypedGoRoute<SellingRoute>(path: '/')
class SellingRoute extends GoRouteData {
  const SellingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Selling();
}

@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Home();
}

@TypedGoRoute<StoreRoute>(path: '/store')
class StoreRoute extends GoRouteData {
  const StoreRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Store();
}

@TypedGoRoute<InventoryRoute>(
  path: '/inventory',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<InventoryFormRoute>(
      path: 'form',
    ),
    TypedGoRoute<InventoryHistoryRoute>(
      path: 'history',
    )
  ],
)
class InventoryRoute extends GoRouteData {
  const InventoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Inventory();
}

class InventoryFormRoute extends GoRouteData {
  const InventoryFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const InventoryForm();
}

class InventoryHistoryRoute extends GoRouteData {
  const InventoryHistoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const InventoryHistoryScreen();
}

@TypedGoRoute<ReportRoute>(path: '/report')
class ReportRoute extends GoRouteData {
  const ReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Report();
}

@TypedGoRoute<AuditRoute>(path: '/audit')
class AuditRoute extends GoRouteData {
  const AuditRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const AuditLogs();
}

@TypedGoRoute<UserRoute>(
  path: '/users',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<UserFormRoute>(
      path: 'form',
    )
  ],
)
class UserRoute extends GoRouteData {
  const UserRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Users();
}

class UserFormRoute extends GoRouteData {
  const UserFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => UserForm();
}

@TypedGoRoute<CustomerRoute>(
  path: '/customer',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<CustomerFormRoute>(
      path: 'form',
    )
  ],
)
class CustomerRoute extends GoRouteData {
  const CustomerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Customer();
}

class CustomerFormRoute extends GoRouteData {
  const CustomerFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => CustomerForm();
}

@TypedGoRoute<CsvPreviewRoute>(path: '/csv-preview')
class CsvPreviewRoute extends GoRouteData {
  const CsvPreviewRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const CsvPreview();
}

@TypedGoRoute<PrintSettingRoute>(path: '/print-setting')
class PrintSettingRoute extends GoRouteData {
  const PrintSettingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrintSetting();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Login();
}

@TypedGoRoute<RegisterRoute>(path: '/register')
class RegisterRoute extends GoRouteData {
  const RegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Register();
}

@TypedGoRoute<RentRoute>(
  path: '/rent',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<RentItemFormRoute>(
      path: 'form',
    )
  ],
)
class RentRoute extends GoRouteData {
  const RentRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Rent();
}

class RentItemFormRoute extends GoRouteData {
  const RentItemFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => RentItemForm();
}

@TypedGoRoute<PresenceRoute>(path: '/presence')
class PresenceRoute extends GoRouteData {
  const PresenceRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Presence();
}

@TypedGoRoute<ExpensesRoute>(path: '/expenses')
class ExpensesRoute extends GoRouteData {
  const ExpensesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Expanses();
}

@TypedGoRoute<SyncRoute>(path: '/sync')
class SyncRoute extends GoRouteData {
  const SyncRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Sync();
}

@TypedGoRoute<SalariesRoute>(
  path: '/salaries',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<SalariesFormRoute>(
      path: 'form',
    )
  ],
)
class SalariesRoute extends GoRouteData {
  const SalariesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Salaries();
}

class SalariesFormRoute extends GoRouteData {
  const SalariesFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SalariesForm();
}

@TypedGoRoute<DuePaymentRoute>(
  path: '/due-payment',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<DuePaymentFormRoute>(
      path: 'form',
    )
  ],
)
class DuePaymentRoute extends GoRouteData {
  const DuePaymentRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const DuePayment();
}

class DuePaymentFormRoute extends GoRouteData {
  const DuePaymentFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => DuePaymentForm();
}

@TypedGoRoute<RequestRoute>(
  path: '/request',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<RequestFormRoute>(
      path: 'form',
    )
  ],
)
class RequestRoute extends GoRouteData {
  const RequestRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Request();
}

class RequestFormRoute extends GoRouteData {
  const RequestFormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RequestForm();
}

@TypedGoRoute<TestingRoute>(path: '/testing')
class TestingRoute extends GoRouteData {
  const TestingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const TestingPage();
}

@TypedGoRoute<DatabaseHealthRoute>(path: '/database-health')
class DatabaseHealthRoute extends GoRouteData {
  const DatabaseHealthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DatabaseHealthScreen();
}

@TypedGoRoute<PendingReceiptsRoute>(path: '/pending-receipts')
class PendingReceiptsRoute extends GoRouteData {
  const PendingReceiptsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PendingReceiptsScreen();
}

@TypedGoRoute<PrintedBillsRoute>(path: '/printed-bills')
class PrintedBillsRoute extends GoRouteData {
  const PrintedBillsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrintedBillsScreen();
}
