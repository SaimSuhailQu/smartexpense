import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/loan.dart';
import 'package:smartexpense/models/payment.dart';
import 'package:smartexpense/services/loan_service.dart';
import 'package:smartexpense/services/currency_service.dart';

class LoanDetailsScreen extends StatelessWidget {
  final Loan loan;

  const LoanDetailsScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loan.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoanSummary(context),
            const SizedBox(height: 24),
            _buildAddPaymentForm(context),
            const SizedBox(height: 24),
            _buildPaymentsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanSummary(BuildContext context) {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loan Summary', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            _buildSummaryRow('Total Amount:', currencyService.formatAmount(loan.amount)),
            const SizedBox(height: 8),
            _buildSummaryRow('Remaining Amount:', currencyService.formatAmount(loan.remainingAmount)),
            const SizedBox(height: 8),
            _buildSummaryRow('Date:', '${loan.date.day}/${loan.date.month}/${loan.date.year}'),
            const SizedBox(height: 8),
            _buildSummaryRow('Type:', loan.type),
            if (loan.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('Notes:', loan.notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  Widget _buildAddPaymentForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Repayment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final currencyService = Provider.of<CurrencyService>(context, listen: false);
                final loanService = Provider.of<LoanService>(context, listen: false);
                
                final payment = Payment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: currencyService.parseAmount(amountController.text),
                  date: DateTime.now(),
                  notes: notesController.text,
                );
                
                loanService.addRepayment(loan.id, payment).then((_) {
                  // Create SnackBar outside of async gap
                  const snackBar = SnackBar(content: Text('Payment added successfully'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                }).catchError((error) {
                  const snackBar = SnackBar(content: Text('Error occurred'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                });
              }
            },
            child: const Text('Add Payment'),
          ),

        ],
      ),
    );
  }

  Widget _buildPaymentsList(BuildContext context) {
    final loanService = Provider.of<LoanService>(context, listen: false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        StreamBuilder<List<Payment>>(
          stream: loanService.getPaymentsStream(loan.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final payments = snapshot.data ?? [];
            
            if (payments.isEmpty) {
              return const Text('No payments recorded yet.');
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return ListTile(
                  title: Text(Provider.of<CurrencyService>(context, listen: false).formatAmount(payment.amount)),
                  subtitle: Text('${payment.date.day}/${payment.date.month}/${payment.date.year}'),
                  trailing: Text(payment.notes),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
