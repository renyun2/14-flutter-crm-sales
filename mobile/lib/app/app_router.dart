import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_provider.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/contracts/presentation/contracts_page.dart';
import '../features/customers/presentation/customers_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/leads/presentation/lead_detail_page.dart';
import '../features/leads/presentation/leads_page.dart';
import '../features/opportunities/presentation/opportunities_page.dart';
import '../features/products/presentation/products_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/quotes/presentation/quotes_page.dart';
import '../features/reports/presentation/reports_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/tasks/presentation/tasks_page.dart';
import '../features/visits/presentation/visits_page.dart';
import 'router_refresh.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authed = ref.read(authProvider) != null;
      final loc = state.matchedLocation;
      const public = ['/', '/login'];
      if (public.contains(loc)) {
        if (authed && loc == '/login') return '/dashboard';
        return null;
      }
      if (!authed) return '/login';
      if (loc == '/approvals') {
        final role = ref.read(authProvider)?.user.role;
        if (role != 'manager' && role != 'admin') return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/customers', builder: (_, __) => const CustomersPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/opportunities', builder: (_, __) => const OpportunitiesPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/leads', builder: (_, __) => const LeadsPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/lead/create', builder: (_, __) => const LeadCreatePage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/lead/:id', builder: (_, s) => LeadDetailPage(leadId: s.pathParameters['id']!)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/opportunity/:id', builder: (_, s) => OpportunityDetailPage(opportunityId: s.pathParameters['id']!)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/customer/create', builder: (_, __) => const CustomerCreatePage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/customer/:id', builder: (_, s) => Customer360Page(customerId: s.pathParameters['id']!)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/customer/:id/contacts', builder: (_, s) => ContactsPage(customerId: s.pathParameters['id']!)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/visits', builder: (_, __) => const VisitsPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/visit/create', builder: (_, __) => const VisitCreatePage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/visit/:id', builder: (_, s) => VisitDetailPage(visitId: s.pathParameters['id']!)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/quotes', builder: (_, __) => const QuotesPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/quote/:id', builder: (_, s) => QuoteEditPage(quoteId: s.pathParameters['id']!)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/contracts', builder: (_, __) => const ContractsPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/contract/:id', builder: (_, s) => ContractDetailPage(contractId: s.pathParameters['id']!)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/approvals', builder: (_, __) => const ApprovalsPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/tasks', builder: (_, __) => const TasksPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/reports', builder: (_, __) => const ReportsPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/products', builder: (_, __) => const ProductsPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/notifications', builder: (_, __) => const NotificationsPage()),
    ],
  );
});
