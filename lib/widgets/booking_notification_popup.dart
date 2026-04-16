import 'package:flutter/material.dart';
import 'package:driver/models/booking_model.dart';
import 'package:driver/utils/app_theme.dart';

class BookingNotificationPopup extends StatelessWidget {
  final BookingModel booking;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const BookingNotificationPopup({
    Key? key,
    required this.booking,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: const EdgeInsets.all(AppPadding.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.mediumGray,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: AppPadding.lg),
            ),

            // Title
            Text(
              '📲 New Booking Request',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppPadding.lg),

            // Booking Details Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primaryYellow, width: 1),
              ),
              padding: const EdgeInsets.all(AppPadding.md),
              child: Column(
                children: [
                  // Seats Booked
                  _buildDetailRow(
                    context,
                    icon: Icons.event_seat,
                    label: 'Seats Booked',
                    value: '${booking.seatsBooked}',
                    valueColor: AppColors.successGreen,
                  ),
                  const Divider(height: AppPadding.md),

                  // Pickup Location
                  _buildDetailRow(
                    context,
                    icon: Icons.location_on,
                    label: 'Pickup',
                    value: booking.pickupLocation,
                    isLong: true,
                  ),
                  const Divider(height: AppPadding.md),

                  // Dropoff Location
                  _buildDetailRow(
                    context,
                    icon: Icons.location_on_outlined,
                    label: 'Dropoff',
                    value: booking.dropoffLocation,
                    isLong: true,
                  ),
                  const Divider(height: AppPadding.md),

                  // Price per Seat
                  _buildDetailRow(
                    context,
                    icon: Icons.local_taxi,
                    label: 'Price per Seat',
                    value: '₹${booking.pricePerSeat.toStringAsFixed(2)}',
                  ),
                  const Divider(height: AppPadding.md),

                  // Total Price
                  _buildDetailRow(
                    context,
                    icon: Icons.price_check,
                    label: 'Total Price',
                    value: '₹${booking.totalPrice.toStringAsFixed(2)}',
                    valueColor: AppColors.primaryYellow,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.xl),

            // Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onAccept,
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlack,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  isLoading ? 'Accepting...' : 'Accept Booking',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppPadding.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  disabledBackgroundColor: AppColors.mediumGray.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: AppPadding.md),

            // Reject Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onReject,
                icon: const Icon(Icons.cancel),
                label: const Text(
                  'Reject Booking',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppPadding.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  disabledBackgroundColor: AppColors.mediumGray.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isLong = false,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.sm),
      child: Row(
        crossAxisAlignment: isLong ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.primaryYellow,
            size: 20,
          ),
          const SizedBox(width: AppPadding.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? AppColors.primaryBlack,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: isLong ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
