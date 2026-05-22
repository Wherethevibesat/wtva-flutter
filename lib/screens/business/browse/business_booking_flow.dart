import 'package:flutter/material.dart';
import '../../../models/business/business_models.dart';
import '../../../services/business_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';

/// #04_04 Book user → payment → booking request → confirmed.
class BusinessBookUserScreen extends StatefulWidget {
  final BusinessTalentProfile user;

  const BusinessBookUserScreen({super.key, required this.user});

  @override
  State<BusinessBookUserScreen> createState() => _BusinessBookUserScreenState();
}

class _BusinessBookUserScreenState extends State<BusinessBookUserScreen> {
  DateTime _when = DateTime.now().add(const Duration(days: 1));
  final _note = TextEditingController(text: 'VIP table · 2 guests');
  double _amount = 150;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Book user', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Invite ${widget.user.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date & time', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${_when.month}/${_when.day}/${_when.year} · ${_when.hour}:${_when.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: WtvaColors.neutral300),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _when,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (d == null || !mounted) return;
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
              if (t == null || !mounted) return;
              setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Note for guest'),
          ),
          const SizedBox(height: 16),
          Text('Offer amount: \$${_amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _amount,
            min: 50,
            max: 500,
            divisions: 9,
            activeColor: WtvaColors.neutral50,
            onChanged: (v) => setState(() => _amount = v),
          ),
          const SizedBox(height: 24),
          WtvaGradientButton(
            label: 'Continue to payment',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BusinessBookingPaymentScreen(
                  user: widget.user,
                  when: _when,
                  amount: _amount,
                  note: _note.text.trim(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessBookingPaymentScreen extends StatefulWidget {
  final BusinessTalentProfile user;
  final DateTime when;
  final double amount;
  final String note;

  const BusinessBookingPaymentScreen({
    super.key,
    required this.user,
    required this.when,
    required this.amount,
    required this.note,
  });

  @override
  State<BusinessBookingPaymentScreen> createState() => _BusinessBookingPaymentScreenState();
}

class _BusinessBookingPaymentScreenState extends State<BusinessBookingPaymentScreen> {
  String _method = 'card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Payment method', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _payTile('card', 'Card ending 4242', Icons.credit_card),
          _payTile('apple', 'Apple Pay', Icons.apple),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: WtvaColors.dark400, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total'),
                Text('\$${widget.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          WtvaGradientButton(
            label: 'Send booking request',
            onPressed: () async {
              final booking = await BusinessService.instance.addBooking(
                talent: widget.user,
                eventAt: widget.when,
                amount: widget.amount,
                note: widget.note,
              );
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => BusinessBookingRequestScreen(bookingId: booking.id),
                ),
                (r) => r.isFirst,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _payTile(String id, String label, IconData icon) {
    final sel = _method == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sel ? WtvaColors.neutral50 : WtvaColors.night200),
      ),
      child: ListTile(
        leading: Icon(icon, color: WtvaColors.neutral200),
        title: Text(label),
        trailing: sel ? const Icon(Icons.check_circle, color: WtvaColors.neutral50) : null,
        onTap: () => setState(() => _method = id),
      ),
    );
  }
}

class BusinessBookingRequestScreen extends StatelessWidget {
  final String bookingId;

  const BusinessBookingRequestScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final booking = BusinessService.instance.bookingById(bookingId);
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Booking request', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.hourglass_top, size: 64, color: WtvaColors.neutral200),
            const SizedBox(height: 16),
            const Text('Request sent', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Waiting for ${booking?.talentName ?? 'guest'} to accept.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: WtvaColors.neutral300),
            ),
            const Spacer(),
            WtvaGradientButton(
              label: 'Simulate confirmed',
              onPressed: () {
                BusinessService.instance.advanceBooking(bookingId, BusinessBookingStatus.confirmed);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BusinessBookingConfirmedScreen(bookingId: bookingId)),
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Back to browse'),
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessBookingConfirmedScreen extends StatelessWidget {
  final String bookingId;

  const BusinessBookingConfirmedScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final b = BusinessService.instance.bookingById(bookingId);
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(backgroundColor: WtvaColors.dark500, title: const Text('Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: WtvaColors.neutral50),
            const SizedBox(height: 16),
            Text('${b?.talentName} confirmed', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            WtvaGradientButton(
              label: 'Mark checked in',
              onPressed: () {
                BusinessService.instance.advanceBooking(bookingId, BusinessBookingStatus.checkedIn);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BusinessBookingCheckedInScreen(bookingId: bookingId)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessBookingCheckedInScreen extends StatelessWidget {
  final String bookingId;

  const BusinessBookingCheckedInScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(backgroundColor: WtvaColors.dark500, title: const Text('Checked in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 64, color: WtvaColors.neutral50),
            const SizedBox(height: 16),
            const Text('Guest checked in at your venue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const Spacer(),
            WtvaGradientButton(
              label: 'Done',
              onPressed: () {
                showWtvaSnack(context, 'Booking complete (demo)', icon: Icons.done);
                Navigator.popUntil(context, (r) => r.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
