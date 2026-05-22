import 'package:flutter/material.dart';
import '../../../models/business/business_models.dart';
import '../../../services/business_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../widgets/business/business_widgets.dart';
import '../browse/business_booking_flow.dart';
import '../browse/business_browse_flow.dart';

/// #06 Booking history + details.
class BusinessBookingsScreen extends StatelessWidget {
  const BusinessBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BusinessService.instance,
      builder: (context, _) {
        final bookings = BusinessService.instance.bookings;
        return Scaffold(
          backgroundColor: WtvaColors.dark500,
          appBar: AppBar(
            backgroundColor: WtvaColors.dark500,
            title: const Text('Booking history', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (bookings.isEmpty)
                const Center(child: Text('No bookings yet', style: TextStyle(color: WtvaColors.neutral300)))
              else
                ...bookings.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BookingTile(booking: b),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BusinessBooking booking;

  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final when = booking.eventAt;
    return BusinessCard(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BusinessBookingDetailScreen(bookingId: booking.id)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.talentName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${when.month}/${when.day} · ${when.hour}:${when.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(booking.status.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('\$${booking.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
          ],
        ),
      ),
    );
  }
}

class BusinessBookingDetailScreen extends StatelessWidget {
  final String bookingId;

  const BusinessBookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final b = BusinessService.instance.bookingById(bookingId);
    if (b == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }
    return FutureBuilder<BusinessTalentProfile?>(
      future: BusinessService.instance.talentById(b.talentId),
      builder: (context, talentSnap) {
        final talent = talentSnap.data;
        return _BookingDetailBody(booking: b, talent: talent);
      },
    );
  }
}

class _BookingDetailBody extends StatelessWidget {
  final BusinessBooking booking;
  final BusinessTalentProfile? talent;

  const _BookingDetailBody({required this.booking, this.talent});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Booking details', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          BusinessCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.talentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Status: ${b.status.label}', style: const TextStyle(color: WtvaColors.neutral200)),
                Text('Amount: \$${b.amount.toStringAsFixed(0)}', style: const TextStyle(color: WtvaColors.neutral200)),
                Text(b.note, style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13)),
              ],
            ),
          ),
          if (b.status == BusinessBookingStatus.pending) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BusinessBookingRequestScreen(bookingId: b.id)),
                );
              },
              child: const Text('View request'),
            ),
          ],
          if (b.status == BusinessBookingStatus.confirmed) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                BusinessService.instance.advanceBooking(b.id, BusinessBookingStatus.checkedIn);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BusinessBookingCheckedInScreen(bookingId: b.id)),
                );
              },
              child: const Text('Mark checked in'),
            ),
          ],
          if (talent != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BusinessTalentChatScreen(user: talent!)),
                );
              },
              child: const Text('Message guest'),
            ),
          ],
        ],
      ),
    );
  }
}
