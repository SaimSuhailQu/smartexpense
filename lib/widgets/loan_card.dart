import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/loan.dart';
import 'package:smartexpense/models/payment.dart'; // Import Payment model
import 'package:smartexpense/services/loan_service.dart';
import 'package:smartexpense/services/currency_service.dart';

class LoanCard extends StatefulWidget {
  final Loan loan;

  const LoanCard({super.key, required this.loan});

  @override
  State<LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<LoanCard> {
  final _repaymentController = TextEditingController();

  @override
  void dispose() {
    _repaymentController.dispose();
    super.dispose();
  }

  void _showRepaymentDialog() {
    _repaymentController.clear();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currencyService = Provider.of<CurrencyService>(context, listen: false);
        
        return AlertDialog(
          title: const Text('Partial Repayment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loan: ${widget.loan.title}'),
              const SizedBox(height: 10),
              Text('Remaining Amount: ${currencyService.formatAmountWithDecimal(widget.loan.remainingAmount)}'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _repaymentController,
                decoration: InputDecoration(
                  labelText: 'Repayment Amount',
                  prefixText: currencyService.currencySymbol,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _processRepayment,
              child: const Text('Repay'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRepayment() async {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final loanService = Provider.of<LoanService>(context, listen: false);
    
    final repaymentString = _repaymentController.text;
    if (repaymentString.isEmpty) {
      // Show snackbar using root context to avoid "use_build_context_synchronously" warning
      const snackBar = SnackBar(
        content: Text('Please enter a repayment amount'),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    
    final repaymentAmount = currencyService.parseAmount(repaymentString);
    
    if (repaymentAmount <= 0) {
      const snackBar = SnackBar(
        content: Text('Please enter a valid repayment amount'),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    
    if (repaymentAmount > widget.loan.remainingAmount) {
      const snackBar = SnackBar(
        content: Text('Repayment amount exceeds remaining loan amount'),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    
    try {
      // Create a Payment object
      final payment = Payment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: repaymentAmount,
        date: DateTime.now(),
        notes: 'Partial repayment',
      );
      
      await loanService.addRepayment(widget.loan.id, payment);
      
      if (mounted) {
        Navigator.pop(context); // Close the dialog
        const snackBar = SnackBar(
          content: Text('Repayment processed successfully!'),
          backgroundColor: Colors.green,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (error) {
      if (mounted) {
        final snackBar = SnackBar(
          content: Text('Failed to process repayment: $error'),
          backgroundColor: Colors.red,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }


  Future<void> _deleteLoan() async {
    final loanService = Provider.of<LoanService>(context, listen: false);
    
    try {
      await loanService.deleteLoan(widget.loan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete loan: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context);
    
    final accentColor = widget.loan.type == 'borrowed' ? Colors.blue : Colors.teal;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withAlpha(isDark ? 31 : 15),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.loan.type == 'borrowed'
                        ? [Colors.blueAccent, Colors.indigoAccent]
                        : [Colors.tealAccent, Colors.greenAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.loan.type == 'borrowed' 
                                  ? Colors.blue.withAlpha(31)
                                  : Colors.teal.withAlpha(31),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.loan.type == 'borrowed' ? 'Borrowed' : 'Lent',
                              style: TextStyle(
                                color: widget.loan.type == 'borrowed' 
                                    ? Colors.blue
                                    : Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.payment, size: 20),
                                onPressed: _showRepaymentDialog,
                                tooltip: 'Partial Repayment',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: _deleteLoan,
                                tooltip: 'Delete Loan',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.loan.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: ${currencyService.formatAmountWithDecimal(widget.loan.amount)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining: ${currencyService.formatAmountWithDecimal(widget.loan.remainingAmount)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: widget.loan.remainingAmount > 0 
                              ? theme.colorScheme.error 
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${widget.loan.date.day}/${widget.loan.date.month}/${widget.loan.date.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                      if (widget.loan.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes: ${widget.loan.notes}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
