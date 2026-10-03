import 'package:flutter/material.dart';
import 'package:pu_taxi_driver/mock/mock_backend.dart';
import 'package:pu_taxi_driver/mock/mock_mode.dart';
import 'package:pu_taxi_driver/services/navigation_service.dart';

/// Wraps the app in a QA mock build with a small "MOCK" tab on the left edge,
/// visible on every screen so a mock session is never mistaken for a real
/// one. Tapping it opens [MockDevPanel]. Only ever mounted when
/// `MockMode.isActive` — see `app/root_main.dart`.
class MockModeOverlay extends StatelessWidget {
  const MockModeOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: MediaQuery.sizeOf(context).height * 0.42,
          child: Material(
            color: const Color(0xE6D32F2F),
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(8)),
            child: InkWell(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(8)),
              onTap: _openPanel,
              child: ValueListenableBuilder<MockSettings>(
                valueListenable: MockMode.changes,
                builder: (_, settings, __) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'MOCK ${settings.speed.toStringAsFixed(0)}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openPanel() {
    // The overlay sits above the Navigator (it wraps the app's builder
    // child), so the sheet needs the navigator's own context.
    final navigatorContext = NavigationService().navigatorKey.currentContext;
    if (navigatorContext == null) return;
    showModalBottomSheet<void>(
      context: navigatorContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const MockDevPanel(),
    );
  }
}

/// Developer controls for the QA mock backend. Deliberately plain Material:
/// it is a debug tool, not part of the product's design system.
class MockDevPanel extends StatelessWidget {
  const MockDevPanel({super.key});

  MockBackend get _backend => MockBackend.instance;

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ValueListenableBuilder<MockSettings>(
        valueListenable: MockMode.changes,
        builder: (context, s, _) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text('QA mock backend', style: texts.titleLarge),
            const SizedBox(height: 4),
            Text(
              'No request reaches the real API. Available in debug and profile '
              'builds made with USE_MOCK_DATA=true — never in release.',
              style: texts.bodySmall,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: _backend.revision,
              builder: (_, __, ___) => Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(_backend.summary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _backend.sendRideRequestNow,
                  child: const Text('Send ride request'),
                ),
                FilledButton.tonal(
                  onPressed: _backend.passengerCancelNow,
                  child: const Text('Passenger cancels'),
                ),
                OutlinedButton(
                  onPressed: _backend.resetTrip,
                  child: const Text('Reset trip'),
                ),
                OutlinedButton(
                  onPressed: _backend.resetAll,
                  child: const Text('Reset all mock data'),
                ),
              ],
            ),
            const Divider(height: 32),
            _label(context, 'Scenario'),
            DropdownButton<MockScenario>(
              isExpanded: true,
              value: s.scenario,
              items: [
                for (final scenario in MockScenario.values)
                  DropdownMenuItem(
                    value: scenario,
                    child: Text('${scenario.label}  (${scenario.wireName})'),
                  ),
              ],
              onChanged: (v) => _update(s.copyWith(scenario: v)),
            ),
            _label(context, 'Simulation speed'),
            SegmentedButton<double>(
              segments: [
                for (final speed in mockSpeeds)
                  ButtonSegment(
                      value: speed,
                      label: Text('${speed.toStringAsFixed(0)}x')),
              ],
              selected: {s.speed},
              onSelectionChanged: (v) => _update(s.copyWith(speed: v.first)),
            ),
            _label(context, 'Ride requests'),
            SegmentedButton<MockDispatch>(
              segments: const [
                ButtonSegment(value: MockDispatch.auto, label: Text('Auto')),
                ButtonSegment(
                    value: MockDispatch.manual, label: Text('Manual')),
              ],
              selected: {s.dispatch},
              onSelectionChanged: (v) => _update(s.copyWith(dispatch: v.first)),
            ),
            _label(context, 'Passenger pays with'),
            SegmentedButton<MockPaymentMethod>(
              segments: [
                for (final m in MockPaymentMethod.values)
                  ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {s.paymentMethod},
              onSelectionChanged: (v) =>
                  _update(s.copyWith(paymentMethod: v.first)),
            ),
            _label(context, 'Driver approval (applies next time Home loads)'),
            SegmentedButton<MockApproval>(
              segments: const [
                ButtonSegment(
                    value: MockApproval.approved, label: Text('Approved')),
                ButtonSegment(
                    value: MockApproval.pending, label: Text('Pending')),
                ButtonSegment(
                    value: MockApproval.rejected, label: Text('Rejected')),
              ],
              selected: {s.approval},
              onSelectionChanged: (v) => _update(s.copyWith(approval: v.first)),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ride has a destination'),
              subtitle: const Text('Off: no route, live distance/fare meter'),
              value: s.rideHasDestination,
              onChanged: (v) => _update(s.copyWith(rideHasDestination: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use mock backend'),
              subtitle: const Text('Restart the app to apply'),
              value: s.useMock,
              onChanged: (v) => _update(s.copyWith(useMock: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );

  void _update(MockSettings next) => MockMode.update(next);
}
